part of 'core.dart';

/// Dispose function
typedef DisposeEffect = void Function();

/// The reaction interface
abstract class ReactionInterface {
  /// Indicate if the reaction is dispose
  bool get disposed;

  /// Tries to dispose the effects, if no listeners are present
  // ignore: unused_element
  void _mayDispose();

  /// Disposes the reaction
  void dispose();
}

/// {@template effect}
/// Signals are trackable values, but they are only one half of the equation.
/// To complement those are observers that can be updated by those trackable
/// values. An effect is one such observer; it runs a side effect that depends
/// on signals.
///
/// An effect can be created by using `Effect`.
/// The effect subscribes automatically to any signal used in the callback and
/// reruns when any of them change.
///
/// So let's create an `Effect` that reruns whenever `counter` changes:
/// ```dart
/// // sample signal
/// final counter = Signal(0);
///
/// // effect creation
/// Effect(() {
///     print("The count is now ${counter.value}");
/// });
/// // The effect prints `The count is now 0`;
///
/// // increment the counter
/// counter.value++;
///
/// // The effect prints `The count is now 1`;
/// ```
///
/// The `Effect` method returns a `Dispose` class giving you a more
/// advanced usage:
/// ```dart
/// final dispose = Effect(() {
///     print("The count is now ${counter.value}");
/// });
/// ```
///
/// Whenever you want to stop the effect from running, you just have to call
/// the returned callback of the `Effect` method:
/// ```dart
/// final disposeEffect = Effect(() { /* your code */ });
/// // later
/// disposeEffect(); // this will stop the effect from running
/// ```
///
/// Any effect runs at least once immediately when is created with the current
/// signals values.
///
/// If the first run (the one that happens when the effect is created, unless
/// `autorun` is false) throws and there is no `onError`, the effect is disposed
/// and the error is rethrown. If `onError` itself throws during that first run,
/// the effect is also disposed and the error from `onError` is rethrown.
///
/// An effect created with `autorun: false` (and run later by hand) or with a
/// `delay` stays alive after a failed run. You already have the effect, so
/// you can dispose it yourself.
///
/// Disposing an effect also disposes the effects created inside it.
///
/// > An effect is useless after it is disposed, you must not use it anymore.
/// {@endtemplate}
class Effect implements ReactionInterface {
  /// {@macro effect}
  factory Effect(
    void Function() callback, {
    ErrorCallback? onError,

    /// The name of the effect, useful for logging
    String? name,

    /// Delay each effect reaction
    Duration? delay,

    /// Whether to automatically dispose the effect (defaults to true).
    ///
    /// This happens automatically when all the tracked dependencies are
    /// disposed.
    bool? autoDispose,

    /// Detach effect, default value is [SolidartConfig.detachEffects]
    bool? detach,

    /// Whether to automatically run the effect (defaults to true).
    bool? autorun,
  }) {
    late Effect effect;

    try {
      final effectiveName = name ?? ReactiveName.nameFor('Effect');
      final effectiveAutoDispose = autoDispose ?? SolidartConfig.autoDispose;
      if (delay == null) {
        effect = Effect._internal(
          callback: () => callback(),
          onError: onError,
          name: effectiveName,
          autoDispose: effectiveAutoDispose,
          detach: detach,
        );
      } else {
        final scheduler = createDelayedScheduler(delay);
        var isScheduled = false;

        effect = Effect._internal(
          callback: () {
            if (!isScheduled) {
              isScheduled = true;
              // dispose() cancels this timer.
              effect._timer = scheduler(() {
                isScheduled = false;
                callback();
              });
            }
          },
          onError: onError,
          name: effectiveName,
          autoDispose: effectiveAutoDispose,
          detach: detach,
        );
      }
      return effect;
    } finally {
      if (autorun ?? true) {
        // The batch holds back the effects queued by the first run. A failed
        // effect is disposed before they run, so it cannot run again. The
        // caller gets the first error; later errors go to the zone.
        reactiveSystem.startBatch();
        final errors = _FirstError()..run(effect.run);
        if (errors.hasError) errors.run(effect.dispose);
        errors.run(reactiveSystem.endBatch);
        // The caller gets no handle when this factory throws.
        if (errors.hasError) errors.run(effect.dispose);
        errors.rethrowIfAny();
      }
    }
  }

  /// {@macro effect}
  Effect._internal({
    required this._callback,
    required this.name,
    required this.autoDispose,
    this._onError,
    bool? detach,
  }) {
    _internalEffect = _AlienEffect(this, _runCallback, detach: detach);
  }

  final VoidCallback _callback;

  // Runs on every run, initial and reactive: routes an error to [_onError]
  // when provided, otherwise rethrows it.
  void _runCallback() {
    try {
      _callback();
    } catch (error, stackTrace) {
      if (_onError == null) rethrow;
      _onError(SolidartCaughtException(error, stackTrace: stackTrace));
    } finally {
      _recordRunDependencies();
    }
  }

  // alien_signals unlinks the dependencies of a nested effect before its
  // cleanup disposes this effect, so dispose() uses this copy. Links after
  // `depsTail` were not read in this run and are about to be purged.
  void _recordRunDependencies() {
    _runDeps.clear();
    final tail = _internalEffect.depsTail;
    if (tail == null) return;
    for (var link = _internalEffect.deps; link != null; link = link.nextDep) {
      _runDeps.add(link.dep);
      if (identical(link, tail)) break;
    }
  }

  /// The name of the effect, useful for logging purposes.
  final String name;

  /// Whether to automatically dispose the effect (defaults to true).
  final bool autoDispose;

  /// Optionally handle the error case
  final ErrorCallback? _onError;

  bool _disposed = false;

  // The pending run of an effect created with a delay.
  Timer? _timer;

  late final _AlienEffect _internalEffect;

  final _deps = <alien_system.ReactiveNode>{};

  // The dependencies read by the latest run.
  final _runDeps = <alien_system.ReactiveNode>{};

  /// The subscriber of the effect, do not use it directly.
  @protected
  alien_system.ReactiveNode get subscriber => _internalEffect;

  @override
  bool get disposed => _disposed;

  /// Runs the effect, tracking any signal read during the execution.
  void run() {
    final currentSub = reactiveSystem.activeSub;
    if (!SolidartConfig.detachEffects && currentSub != null) {
      if (currentSub is! _AlienEffect ||
          (!_internalEffect.detach && !currentSub.detach)) {
        reactiveSystem.link(_internalEffect, currentSub);
        currentSub.flags |= _hasChildEffect;
      }
    }

    final prevSub = reactiveSystem.setCurrentSub(_internalEffect);
    reactiveSystem.startBatch();
    try {
      _internalEffect.run();
    } finally {
      try {
        reactiveSystem.endBatch();
      } finally {
        reactiveSystem.setCurrentSub(prevSub);
        _mayDispose();
      }
    }
  }

  /// Sets the dependencies of the effect, do not use it directly.
  @internal
  void setDependencies(alien_system.ReactiveNode node) {
    _deps
      ..clear()
      ..addAll(node.getDependencies());
  }

  /// Invalidates the effect.
  ///
  /// After this operation the effect is useless.
  void call() => dispose();

  /// Invalidates the effect.
  ///
  /// After this operation the effect is useless.
  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _timer?.cancel();

    // Keep the reads of onDispose callbacks out of the running effect.
    untracked(() {
      final dependencies = {
        ...subscriber.getDependencies(),
        ..._deps,
        ..._runDeps,
      };
      // The batch defers the auto-disposal until the work that disposed this
      // effect ends, for example the rerun of its parent effect.
      reactiveSystem.startBatch();
      try {
        _internalEffect.dispose();
        reactiveSystem._pendingDisposals.addAll(dependencies);
      } finally {
        reactiveSystem.endBatch();
      }
    });
  }

  @override
  void _mayDispose() {
    // Gate on the per-instance `autoDispose` (defaulted from
    // SolidartConfig.autoDispose at creation), consistent with Signal/Computed.
    if (_disposed || !autoDispose) return;
    if (subscriber.deps?.dep == null) {
      dispose();
    }
  }
}
