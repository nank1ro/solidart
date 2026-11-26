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
    final errors = _FirstError();
    var link = subs;
    while (link != null) {
      final next = link.nextSub;
      final sub = link.sub;
      alien.unlink(link, sub);
      // alien_signals checks the dependencies of a pending subscriber before
      // it runs or reads it. Without dependencies, nothing it read changed.
      if (sub.deps == null) sub.flags &= ~alien_system.ReactiveFlags.pending;
      // The saved dependencies of the subscriber must not retain this node.
      if (sub is _AlienEffect) {
        sub.parent
          .._deps.remove(this)
          .._runDeps.remove(this);
        errors.run(sub.parent._mayDispose);
      }
      if (sub is _AlienComputed) errors.run(sub.parent._mayDispose);
      link = next;
    }
    errors.rethrowIfAny();
  }
}

/// Lets a disposal finish when a step throws: [run] keeps the first error,
/// reports later ones to [Zone.current], and [rethrowIfAny] rethrows the first.
class _FirstError {
  Object? _error;
  StackTrace? _stackTrace;

  bool get hasError => _error != null;

  void run(void Function() step) {
    try {
      step();
    } catch (error, stackTrace) {
      if (_error == null) {
        _error = error;
        _stackTrace = stackTrace;
      } else {
        Zone.current.handleUncaughtError(error, stackTrace);
      }
    }
  }

  /// Runs every step of [steps], including the ones added while they run,
  /// then clears [steps].
  void runAll(List<void Function()> steps) {
    for (var i = 0; i < steps.length; i++) {
      run(steps[i]);
    }
    steps.clear();
  }

  void rethrowIfAny() {
    final error = _error;
    if (error != null) Error.throwWithStackTrace(error, _stackTrace!);
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

class ReactiveSystem {
  int get batchDepth => alien.getBatchDepth();

  alien_system.ReactiveNode? get activeSub => alien.getActiveSub();

  // Use setCurrentSub when you need save/restore (returns previous sub).
  // The getter above is provided for read-only inspection.
  alien_system.ReactiveNode? setCurrentSub(alien_system.ReactiveNode? sub) {
    // A nested callback can dispose the effect it was about to restore.
    if (sub is _AlienEffect && sub.parent.disposed) {
      return alien.setActiveSub();
    }
    return alien.setActiveSub(sub);
  }

  void startBatch() => alien.startBatch();

  /// Like `alien.endBatch()`, but runs this class's [flush], so an effect
  /// that throws does not drop the effects queued after it.
  void endBatch() {
    if (--alien.batchDepth == 0) flush();
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
    if (computed.flags == alien_system.ReactiveFlags.none) {
      if (activeSub case final _AlienEffect effect) {
        // On the first read, alien_signals would restore and link the effect
        // even if the selector disposed it. Subscribe only if it is alive.
        return _evaluate(() {
          try {
            return untracked(computed.get);
          } finally {
            if (!effect.parent.disposed) link(computed, effect);
          }
        });
      }
    }
    return _evaluate(computed.get);
  }

  // The number of Computed evaluations running. Until the outermost one ends,
  // the dependencies of the child effects it stops stay pending, so a
  // recreated child subscribes to them first (see issue #202).
  int _evaluationDepth = 0;

  T _evaluate<T>(T Function() evaluation) {
    _evaluationDepth++;
    return _runThen(evaluation, () {
      if (--_evaluationDepth == 0 &&
          batchDepth == 0 &&
          _pendingDisposals.isNotEmpty) {
        flush();
      }
    });
  }

  /// Runs [body], then [after]. When [body] throws, its error reaches the
  /// caller with its stack trace, and an error from [after] goes to the zone.
  T _runThen<T>(T Function() body, void Function() after) {
    final T result;
    try {
      result = body();
    } catch (_) {
      try {
        after();
      } catch (error, stackTrace) {
        Zone.current.handleUncaughtError(error, stackTrace);
      }
      rethrow;
    }
    after();
    return result;
  }

  Option<T> getSignalValue<T>(_AlienSignal<T> signal) {
    return signal.get();
  }

  void setSignalValue<T>(_AlienSignal<T> signal, Option<T> value) {
    // Batch the write so the queued effects run in [flush] below, not in
    // alien_signals' own flush.
    startBatch();
    try {
      signal.set(value);
    } finally {
      endBatch();
    }
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

  /// Notifies the subscribers of [node] that its value changed outside a
  /// propagation, as `trigger` does, and runs the queued effects.
  void notifySubscribers(alien_system.ReactiveNode node) {
    final subs = node.subs;
    if (subs == null) return;
    propagate(subs);
    // The subscribers must update: [node] itself is no longer dirty.
    alien.shallowPropagate(subs);
    if (batchDepth == 0) flush();
  }

  bool _flushing = false;

  // The dependencies of the effects and computeds disposed since the last
  // drain.
  final _pendingDisposals = <alien_system.ReactiveNode>{};

  /// Runs every queued effect, then rethrows the first error, if any.
  ///
  /// Replaces alien_signals' `flush`, which stops at the first throwing effect
  /// and drops the effects queued after it (see issue #182).
  ///
  /// Only one flush runs at a time. A write inside an effect only queues
  /// effects, and the running flush runs them after that effect ends.
  ///
  /// When the queue is empty and no Computed evaluation runs, the pending
  /// dependencies of disposed effects and computeds get auto-disposal. A
  /// parent that reruns has then subscribed its new children, so the
  /// dependencies they read again stay alive (see issue #202).
  void flush() {
    if (_flushing) return;
    _flushing = true;
    Object? error;
    StackTrace? stackTrace;
    try {
      do {
        while (alien.queuedEffects != null) {
          final effect = alien.queuedEffects! as alien.EffectNode;
          alien.queuedEffects = effect.nextEffect;
          effect.nextEffect = null;
          if (alien.queuedEffects == null) alien.queuedEffectsTail = null;
          try {
            alien.run(effect);
          } catch (e, s) {
            if (error == null) {
              error = e;
              stackTrace = s;
            }
          }
        }
        try {
          if (_evaluationDepth == 0) _disposePending();
        } catch (e, s) {
          if (error == null) {
            error = e;
            stackTrace = s;
          } else {
            Zone.current.handleUncaughtError(e, s);
          }
        }
        // An onDispose callback can write a signal and queue effects.
      } while (alien.queuedEffects != null);
    } finally {
      _flushing = false;
    }
    if (error != null) Error.throwWithStackTrace(error, stackTrace!);
  }

  // Offers auto-disposal to the pending dependencies, untracked. Stops when an
  // onDispose callback queues an effect: [flush] runs it, then resumes.
  // Rethrows the first error; later ones go to the zone.
  void _disposePending() {
    final errors = _FirstError();
    untracked(() {
      while (_pendingDisposals.isNotEmpty && alien.queuedEffects == null) {
        final dep = _pendingDisposals.first;
        _pendingDisposals.remove(dep);
        switch (dep) {
          case _AlienSignal():
            errors.run(dep.parent._mayDispose);
          case _AlienComputed():
            errors.run(dep.parent._mayDispose);
        }
      }
    });
    errors.rethrowIfAny();
  }
}
