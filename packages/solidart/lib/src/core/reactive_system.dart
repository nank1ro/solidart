// ignore: lines_longer_than_80_chars
// ignore_for_file: public_member_api_docs, parameter_assignments, library_private_types_in_public_api
//
// Reactive flags map: https://github.com/medz/alien-signals-dart/blob/main/flags.md
part of 'core.dart';

extension MayDisposeDependencies on alien.ReactiveNode {
  List<alien.ReactiveNode> getDependencies() {
    final deps = <alien.ReactiveNode>[];
    var link = this.deps;
    for (; link != null; link = link.nextDep) {
      deps.add(link.dep);
    }
    return deps;
  }

  void mayDisposeDependencies([Iterable<alien.ReactiveNode>? include]) {
    final dependencies =
        Set<alien.ReactiveNode>.from(getDependencies()..addAll(include ?? []));
    for (final dep in dependencies) {
      return switch (dep) {
        _AlienSignal() => dep.parent._mayDispose(),
        _AlienComputed() => dep.parent._mayDispose(),
        _ => null,
      };
    }
  }
}

typedef ReactionErrorHandler = void Function(
  Object error,
  ReactionInterface reaction,
);

class ReactiveName {
  ReactiveName._internal();
  static final _instance = ReactiveName._internal();

  int nextIdCounter = 0;

  int get nextId => ++nextIdCounter;

  static String nameFor(String prefix) {
    assert(prefix.isNotEmpty, 'the prefix cannot be empty');
    return '$prefix@${_instance.nextId}';
  }
}

@protected
final reactiveSystem = ReactiveSystem();

class ReactiveSystem extends alien.ReactiveSystem {
  int batchDepth = 0;
  alien.ReactiveNode? activeSub;
  _AlienEffect? queuedEffects;
  _AlienEffect? queuedEffectsTail;

  @override
  void notify(alien.ReactiveNode node) {
    final flags = node.flags;
    if ((flags & 64 /* Queued */) == 0) {
      node.flags = flags | 64 /* Queued */;
      final subs = node.subs;
      if (subs != null) {
        notify(subs.sub);
      } else if (queuedEffectsTail != null) {
        queuedEffectsTail =
            queuedEffectsTail!.nextEffect = node as _AlienEffect;
      } else {
        queuedEffectsTail = queuedEffects = node as _AlienEffect;
      }
    }
  }

  @override
  void unwatched(alien.ReactiveNode node) {
    if (node is _AlienComputed) {
      var toRemove = node.deps;
      if (toRemove != null) {
        node.flags = 17 /* Mutable | Dirty */;
        do {
          toRemove = unlink(toRemove!, node);
        } while (toRemove != null);
      }
    } else if (node is! _AlienSignal) {
      stopEffect(node);
    }
  }

  @override
  bool update(alien.ReactiveNode node) {
    assert(
      node is _AlienUpdatable,
      'Reactive node type must be signal or computed',
    );
    return (node as _AlienUpdatable).update();
  }

  void startBatch() => ++batchDepth;
  void endBatch() {
    if ((--batchDepth) == 0) flush();
  }

  alien.ReactiveNode? setCurrentSub(alien.ReactiveNode? sub) {
    final prevSub = activeSub;
    activeSub = sub;
    return prevSub;
  }

  T getComputedValue<T>(_AlienComputed<T> computed) {
    final flags = computed.flags;
    if ((flags & 16 /* Dirty */) != 0 ||
        ((flags & 32 /* Pending */) != 0 &&
            checkDirty(computed.deps!, computed))) {
      if (computed.update()) {
        final subs = computed.subs;
        if (subs != null) shallowPropagate(subs);
      }
    } else if ((flags & 32 /* Pending */) != 0) {
      computed.flags = flags & -33 /* ~Pending */;
    }
    if (activeSub != null) {
      link(computed, activeSub!);
    }

    return computed.value as T;
  }

  Option<T> getSignalValue<T>(_AlienSignal<T> signal) {
    final value = signal.value;
    if ((signal.flags & 16 /* Dirty */) != 0) {
      if (signal.update()) {
        final subs = signal.subs;
        if (subs != null) shallowPropagate(subs);
      }
    }

    if (activeSub != null) link(signal, activeSub!);
    return value;
  }

  void setSignalValue<T>(_AlienSignal<T> signal, Option<T> value) {
    if (signal.value != (signal.value = value)) {
      signal.flags = 17 /* Mutable | Dirty */;
      final subs = signal.subs;
      if (subs != null) {
        propagate(subs);
        if (batchDepth == 0) flush();
      }
    }
  }

  void stopEffect(alien.ReactiveNode effect) {
    assert(effect is! _AlienSignal, 'Reactive node type not matched');
    var dep = effect.deps;
    while (dep != null) {
      dep = unlink(dep, effect);
    }

    final sub = effect.subs;
    if (sub != null) unlink(sub, effect);
    effect.flags = 0 /* None */;
  }

  void run(alien.ReactiveNode effect, int flags) {
    if ((flags & 16 /* Dirty */) != 0 ||
        ((flags & 32 /* Pending */) != 0 && checkDirty(effect.deps!, effect))) {
      final prevSub = setCurrentSub(effect);
      startTracking(effect);
      try {
        (effect as _AlienEffect).run();
      } finally {
        activeSub = prevSub;
        endTracking(effect);
      }
      return;
    } else if ((flags & 32 /* Pending */) != 0) {
      effect.flags = flags & -33 /* ~Pending */;
    }
    var link = effect.deps;
    while (link != null) {
      final dep = link.dep;
      final depFlags = dep.flags;
      if ((depFlags & 64 /* Queued */) != 0) {
        run(dep, dep.flags = depFlags & -65 /* ~Queued */);
      }
      link = link.nextDep;
    }
  }

  void flush() {
    while (queuedEffects != null) {
      final effect = queuedEffects!;
      if ((queuedEffects = effect.nextEffect) != null) {
        effect.nextEffect = null;
      } else {
        queuedEffectsTail = null;
      }

      run(effect, effect.flags &= -65 /* ~Queued */);
    }
  }
}
