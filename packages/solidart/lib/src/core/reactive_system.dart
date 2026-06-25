// ignore_for_file: public_member_api_docs, library_private_types_in_public_api
//
// Reactive flags map: https://github.com/medz/alien-signals-dart/blob/main/flags.md
part of 'core.dart';

// alien_signals' internal `hasChildEffect` flag (value 64) is deliberately
// hidden from its public barrel exports (`preset.dart` hides it). We redeclare
// it here so the reactive adapter can test and set this bit without reaching
// into unpublished internals. If the upstream value ever changes, the adjacent
// link in alien/src/preset.dart → `const hasChildEffect = 64` should be
// cross-checked.
const _hasChildEffect = 64 as alien_system.ReactiveFlags;

extension MayDisposeDependencies on alien_system.ReactiveNode {
  Iterable<alien_system.ReactiveNode> getDependencies() {
    var link = deps;
    final foundDeps = <alien_system.ReactiveNode>{};
    for (; link != null; link = link.nextDep) {
      foundDeps.add(link.dep);
    }
    return foundDeps;
  }

  void mayDisposeDependencies([Iterable<alien_system.ReactiveNode>? include]) {
    final dependencies = {...getDependencies(), ...?include};
    for (final dep in dependencies) {
      switch (dep) {
        case _AlienSignal():
          dep.parent._mayDispose();
        case _AlienComputed():
          dep.parent._mayDispose();
      }
    }
  }
}

typedef ReactionErrorHandler =
    void Function(Object error, ReactionInterface reaction);

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

class ReactiveSystem {
  int get batchDepth => alien.getBatchDepth();

  alien_system.ReactiveNode? get activeSub => alien.getActiveSub();

  // Use setCurrentSub when you need save/restore (returns previous sub).
  // The getter above is provided for read-only inspection.
  alien_system.ReactiveNode? setCurrentSub(alien_system.ReactiveNode? sub) {
    return alien.setActiveSub(sub);
  }

  void startBatch() => alien.startBatch();

  void endBatch() => alien.endBatch();

  void link(alien_system.ReactiveNode dep, alien_system.ReactiveNode sub) {
    alien.link(dep, sub, alien.cycle);
  }

  T getComputedValue<T>(_AlienComputed<T> computed) {
    // After a dependency is disposed, `ReadableSignal.dispose` nulls this
    // computed's `deps` but leaves the producer's `subs` link dangling, so a
    // later write to the disposed signal can still mark an `autoDispose: false`
    // computed `pending` while `deps == null`. Clear it here, otherwise
    // upstream `ComputedNode.get()` takes the `checkDirty(deps!, …)` branch and
    // null-asserts. (see test "Check Computed do not autoDisposes if no longer
    // used")
    if ((computed.flags & alien_system.ReactiveFlags.pending) !=
            alien_system.ReactiveFlags.none &&
        computed.deps == null) {
      computed.flags &= ~alien_system.ReactiveFlags.pending;
    }

    return computed.get();
  }

  Option<T> getSignalValue<T>(_AlienSignal<T> signal) {
    return signal.get();
  }

  void setSignalValue<T>(_AlienSignal<T> signal, Option<T> value) {
    signal.set(value);
  }

  void stopEffect(alien_system.ReactiveNode effect) {
    alien.stop(effect);
  }

  // The parameter is `ReactiveNode` rather than `_AlienEffect` only because
  // `_AlienEffect` is library-private and test callers receive it via the
  // `Effect.subscriber` getter (typed as `ReactiveNode`). At runtime every
  // legitimate caller passes an `_AlienEffect`; the assertion below catches
  // misuse in debug mode.
  void runEffect(alien_system.ReactiveNode effect) {
    assert(
      effect is _AlienEffect,
      'runEffect must be called with an _AlienEffect',
    );
    alien.run(effect as _AlienEffect);
  }

  void propagate(alien_system.Link link) {
    alien.propagate(link, alien.runDepth > 0);
  }

  void flush() => alien.flush();
}
