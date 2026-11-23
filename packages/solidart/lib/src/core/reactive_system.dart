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

  /// The number of subscribers currently observing this node.
  int get subscriberCount {
    var count = 0;
    for (var link = subs; link != null; link = link.nextSub) {
      count++;
    }
    return count;
  }

  /// Unlinks every subscriber from this node, offering each the same
  /// `_mayDispose` chance a disposed dependency triggers. Used when a signal or
  /// computed is disposed — `alien.stop` only unlinks the first subscriber.
  void unlinkSubscribers() {
    var link = subs;
    while (link != null) {
      final next = link.nextSub;
      final sub = link.sub;
      alien.unlink(link, sub);
      if (sub is _AlienEffect) sub.parent._mayDispose();
      if (sub is _AlienComputed) sub.parent._mayDispose();
      link = next;
    }
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

  void endBatch() {
    alien.endBatch();
    _surfaceEffectErrors();
  }

  void link(alien_system.ReactiveNode dep, alien_system.ReactiveNode sub) {
    alien.link(dep, sub, alien.cycle);
  }

  T getComputedValue<T>(_AlienComputed<T> computed) {
    // Invariant: a computed is never `pending` while detached from the graph
    // (`deps == null`). `pending` is only set by `propagate`, which reaches a
    // node through the very dependency links that make `deps` non-null, and
    // every teardown path (recompute / unwatch / stop / signal dispose) either
    // clears `pending` or fully unlinks the node. If this ever fires, a code
    // path is leaving a half-linked node (e.g. a one-sided unlink), which would
    // otherwise crash in upstream `ComputedNode.get()` via `checkDirty(deps!)`.
    assert(
      computed.deps != null ||
          (computed.flags & alien_system.ReactiveFlags.pending) ==
              alien_system.ReactiveFlags.none,
      'computed is pending while detached (deps == null) — a subscriber link '
      'was not fully unlinked',
    );
    return computed.get();
  }

  Option<T> getSignalValue<T>(_AlienSignal<T> signal) {
    return signal.get();
  }

  void setSignalValue<T>(_AlienSignal<T> signal, Option<T> value) {
    signal.set(value);
    // `signal.set` flushes queued effects synchronously when not inside a
    // batch, so surface any error an effect captured during that flush.
    _surfaceEffectErrors();
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

  void flush() {
    alien.flush();
    _surfaceEffectErrors();
  }

  /// Errors thrown by effect callbacks (without an `onError`) during a flush.
  ///
  /// alien_signals' flush loop aborts on the first throwing effect and drops
  /// the effects still queued behind it (see issue #182). To avoid that, an
  /// effect body never throws out of the loop: its error is captured here and
  /// rethrown once the flush has finished running every queued effect.
  final _capturedEffectErrors = <(Object, StackTrace)>[];

  /// Captures an error thrown by an effect body so the flush loop can keep
  /// running the remaining queued effects.
  void captureEffectError(Object error, StackTrace stackTrace) {
    _capturedEffectErrors.add((error, stackTrace));
  }

  /// Rethrows the first error captured during the current flush, once the
  /// flush has fully unwound. Re-entrant writes performed by an effect (while
  /// `runDepth > 0`) defer to the outermost boundary so the error surfaces
  /// only after every queued effect has run.
  void _surfaceEffectErrors() {
    if (_capturedEffectErrors.isEmpty || alien.runDepth != 0) return;
    final (error, stackTrace) = _capturedEffectErrors.first;
    _capturedEffectErrors.clear();
    Error.throwWithStackTrace(error, stackTrace);
  }
}
