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
/// Effect((_) {
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
/// the `dispose()` callback
///
/// You can also dispose an effect inside the callback
/// ```dart
/// Effect((dispose) {
///     print("The count is now ${counter.value}");
///     if (counter.value == 1) dispose();
/// });
/// ```
///
/// In the example above the effect is disposed when the counter value is equal
/// to 1
///
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
  }) {
    late Effect effect;
    final effectiveName = name ?? ReactiveName.nameFor('Effect');
    final effectiveAutoDispose = autoDispose ?? SolidartConfig.autoDispose;
    if (delay == null) {
      effect = Effect._internal(
        callback: () => callback(),
        onError: onError,
        name: effectiveName,
        autoDispose: effectiveAutoDispose,
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
      );
    }
    effect._schedule();
    return effect;
  }

  /// {@macro effect}
  Effect._internal({
    required VoidCallback callback,
    required this.name,
    required this.autoDispose,
    ErrorCallback? onError,
  }) : _onError = onError {
    _internalEffect = _AlienEffect(callback, parent: this);
  }

  /// The name of the effect, useful for logging purposes.
  final String name;

  /// Whether to automatically dispose the effect (defaults to true).
  final bool autoDispose;

  /// Optionally handle the error case
  final ErrorCallback? _onError;

  bool _disposed = false;

  late final _AlienEffect _internalEffect;

  final _deps = <alien.Dependency>{};

  /// The subscriber of the effect, do not use it directly.
  @protected
  alien.Subscriber get subscriber => _internalEffect;

  @override
  bool get disposed => _disposed;

  void _schedule() {
    try {
      _internalEffect.run();
    } catch (e, s) {
      _onError?.call(SolidartCaughtException(e, stackTrace: s));
    } finally {
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
      // if (dep is Signal) dep._mayDispose();
      // if (dep is Computed) dep._mayDispose();
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
        final dep = link.dep;

        _deps.add(dep);
      }
      if (!autoDispose || _disposed) return;
      if (_internalEffect.deps?.dep == null) {
        dispose();
      }
    }
  }
}
