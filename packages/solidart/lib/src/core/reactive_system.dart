// ignore: lines_longer_than_80_chars
// ignore_for_file: public_member_api_docs, parameter_assignments, library_private_types_in_public_api
part of 'core.dart';

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
  final queuedEffects = <int, alien.ReactiveNode?>{};
  final pauseStack = <alien.ReactiveNode>[];

  int batchDepth = 0;
  int notifyIndex = 0;
  int queuedEffectsLength = 0;
  alien.ReactiveNode? activeSub;

  @override
  void notify(alien.ReactiveNode node) {
    final flags = node.flags;
    if ((flags & alien.EffectFlags.queued) == 0) {
      node.flags = flags | alien.EffectFlags.queued;
      final subs = node.subs;
      if (subs != null) {
        notify(subs.sub);
      } else {
        queuedEffects[queuedEffectsLength++] = node;
      }
    }
  }

  @override
  void unwatched(alien.ReactiveNode node) {
    if (node is _AlienComputed) {
      var toRemove = node.deps;
      if (toRemove != null) {
        // ReactiveFlags.mutable | ReactiveFlags.dirty
        node.flags = 17 as alien.ReactiveFlags;
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
    if ((flags & alien.ReactiveFlags.dirty) != 0 ||
        ((flags & alien.ReactiveFlags.pending) != 0 &&
            checkDirty(computed.deps!, computed))) {
      if (computed.update()) {
        final subs = computed.subs;
        if (subs != null) shallowPropagate(subs);
      }
    } else if ((flags & alien.ReactiveFlags.pending) != 0) {
      computed.flags = flags & -33 /* ~ReactiveFlags.pending */;
    }
    if (activeSub != null) {
      link(computed, activeSub!);
    }

    return computed.value as T;
  }

  Option<T> getSignalValue<T>(_AlienSignal<T> signal) {
    final value = signal.value;
    if ((signal.flags & alien.ReactiveFlags.dirty) != 0) {
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
      signal.flags = 17
          as alien.ReactiveFlags; // ReactiveFlags.mutable | ReactiveFlags.dirty
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
    effect.flags = alien.ReactiveFlags.none;
  }

  void run(alien.ReactiveNode effect, alien.ReactiveFlags flags) {
    if ((flags & alien.ReactiveFlags.dirty) != 0 ||
        ((flags & alien.ReactiveFlags.pending) != 0 &&
            checkDirty(effect.deps!, effect))) {
      final prevSub = setCurrentSub(effect);
      startTracking(effect);
      try {
        (effect as _AlienEffect).run();
      } finally {
        activeSub = prevSub;
        endTracking(effect);
      }
      return;
    } else if ((flags & alien.ReactiveFlags.pending) != 0) {
      effect.flags = flags & -33 /* ~ReactiveFlags.pending */;
    }
    var link = effect.deps;
    while (link != null) {
      final dep = link.dep;
      final depFlags = dep.flags;
      if ((depFlags & alien.EffectFlags.queued) != 0) {
        run(dep, dep.flags = depFlags & -65 /* ~EffectFlags.queued */);
      }
      link = link.nextDep;
    }
  }

  void flush() {
    try {
      while (notifyIndex < queuedEffectsLength) {
        final effect = queuedEffects[notifyIndex];
        queuedEffects[notifyIndex++] = null;
        run(effect!, effect.flags &= -65 /* ~EffectFlags.queued */);
      }
    } finally {
      notifyIndex = queuedEffectsLength = 0;
    }
  }
}
