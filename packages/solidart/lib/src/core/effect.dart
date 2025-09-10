part of 'core.dart';

/// {@template EffectWithoutDependenciesError}
/// This exception would be fired when an effect is created without tracking
/// any dependencies.
/// {@endtemplate}
class EffectWithoutDependenciesError extends Error {
  /// {@macro EffectWithoutDependenciesException}
  EffectWithoutDependenciesError({required this.name});

  /// The name of the effect
  final String name;

  // coverage:ignore-start
  @override
  String toString() =>
      '''EffectWithoutDependenciesException: Effect ($name) was created without tracking any dependencies. Make sure to access at least one reactive value (Signal, Computed, etc.) inside the effect callback.''';
  // coverage:ignore-end
}

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
        Timer? timer;

        effect = Effect._internal(
          callback: () {
            if (!isScheduled) {
              isScheduled = true;

              // coverage:ignore-start
              timer?.cancel();
              // coverage:ignore-end
              timer = null;

              timer = scheduler(() {
                isScheduled = false;
                if (!effect.disposed) {
                  callback();
                } else {
                  // coverage:ignore-start
                  timer?.cancel();
                  // coverage:ignore-end
                }
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
      if (autorun ?? true) effect.run();
    }
  }

  /// {@macro effect}
  Effect._internal({
    required VoidCallback callback,
    required this.name,
    required this.autoDispose,
    ErrorCallback? onError,
    bool? detach,
  }) : _onError = onError {
    _internalEffect = _AlienEffect(this, callback, detach: detach);
  }

  /// The name of the effect, useful for logging purposes.
  final String name;

  /// Whether to automatically dispose the effect (defaults to true).
  final bool autoDispose;

  /// Optionally handle the error case
  final ErrorCallback? _onError;

  bool _disposed = false;

  late final _AlienEffect _internalEffect;

  final _deps = <alien.ReactiveNode>{};

  bool _firstRun = true;

  /// The subscriber of the effect, do not use it directly.
  @protected
  alien.ReactiveNode get subscriber => _internalEffect;

  @override
  bool get disposed => _disposed;

  /// Runs the effect, tracking any signal read during the execution.
  void run() {
    final currentSub = reactiveSystem.activeSub;
    if (!SolidartConfig.detachEffects && currentSub != null) {
      if (currentSub is! _AlienEffect ||
          (!_internalEffect.detach && !currentSub.detach)) {
        reactiveSystem.link(_internalEffect, currentSub);
      }
    }
    final prevSub = reactiveSystem.setCurrentSub(_internalEffect);

    try {
      _internalEffect.run();
    } catch (e, s) {
      if (_onError != null) {
        _onError.call(SolidartCaughtException(e, stackTrace: s));
      } else {
        rethrow;
      }
    } finally {
      reactiveSystem.setCurrentSub(prevSub);
      if (SolidartConfig.autoDispose) {
        Future.microtask(_mayDispose);
      }
    }
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

    _internalEffect.dispose();

    for (final dep in _deps) {
      if (dep is _AlienSignal) dep.parent._mayDispose();
      if (dep is _AlienComputed) dep.parent._mayDispose();
    }

    _deps.clear();
  }

  @override
  void _mayDispose() {
    if (_disposed) return;

    if (SolidartConfig.autoDispose) {
      _deps.clear();
      var link = _internalEffect.deps;

      for (; link != null; link = link.nextDep) {
        _deps.add(link.dep);
      }

      if (_firstRun) {
        _firstRun = false;

        if (_deps.isEmpty) {
          if (_onError != null) {
            _onError.call(EffectWithoutDependenciesError(name: name));
          } else {
            // coverage:ignore-start
            throw EffectWithoutDependenciesError(name: name);
            //  coverage:ignore-end
          }
        }
      }

      if (!autoDispose || _disposed) return;
      if (_internalEffect.deps?.dep == null) {
        dispose();
      }
    }
  }
}
