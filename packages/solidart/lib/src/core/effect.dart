part of 'core.dart';

/// Dispose function
typedef DisposeEffect = void Function();

/// {@template effect-options}
/// The effect options
///
/// The [name] of the effect, useful for logging
/// The [delay] is used to delay each effect reaction
/// {@endtemplate}
@immutable
class EffectOptions {
  /// {@macro effect-options}
  EffectOptions({
    this.name,
    this.delay,
    bool? autoDispose,
  }) : autoDispose = autoDispose ?? SolidartConfig.autoDispose;

  /// The name of the effect, useful for logging
  final String? name;

  /// Delay each effect reaction
  final Duration? delay;

  /// Whether to automatically dispose the effect (defaults to true).
  ///
  /// This happens automatically when all the tracked dependencies are disposed.
  final bool autoDispose;

  // coverage:ignore-start

  /// Creates a copy of this [EffectOptions] with the given [name].
  EffectOptions copyWith({
    String? name,
  }) {
    return EffectOptions(
      name: name ?? this.name,
      delay: delay,
      autoDispose: autoDispose,
    );
  }

  // coverage:ignore-end
}

// coverage:ignore-start

/// {@macro effect}
@Deprecated('Use Effect instead')
DisposeEffect createEffect(
  void Function(DisposeEffect dispose) callback, {
  ErrorCallback? onError,
  EffectOptions? options,
}) {
  return Effect(callback, onError: onError, options: options).dispose;
}
// coverage:ignore-end

/// The reaction interface
abstract class ReactionInterface {
  /// Indicate if the reaction is dispose
  bool get disposed;

  /// Disposes the reaction
  void dispose();

  /// Runs the reaction
  void _run();
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
/// final dispose = Effect((_) {
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
/// signals values
///
/// > An effect is useless after it is disposed, you must not use it anymore.
/// {@endtemplate}
class Effect
    with alien.Dependency, alien.Subscriber
    implements ReactionInterface {
  /// {@macro effect}
  factory Effect(
    void Function(DisposeEffect dispose) callback, {
    ErrorCallback? onError,
    EffectOptions? options,
  }) {
    late Effect effect;
    final name = options?.name ?? 'Effect';
    final effectiveOptions = (options ?? EffectOptions()).copyWith(name: name);
    if (effectiveOptions.delay == null) {
      effect = Effect._internal(
        callback: () => callback(effect.dispose),
        onError: onError,
        options: effectiveOptions,
      );
    } else {
      final scheduler = createDelayedScheduler(effectiveOptions.delay!);
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
                callback(effect.dispose);
              } else {
                // coverage:ignore-start
                timer?.cancel();
                // coverage:ignore-end
              }
            });
          }
        },
        options: effectiveOptions,
        onError: onError,
      );
    }

    if (system.activeSub != null) {
      system.link(effect, system.activeSub!);
    } else if (system.activeScope != null) {
      system.link(effect, system.activeScope!);
    }
    effect._run();

    return effect;
  }

  /// {@macro effect}
  Effect._internal({
    required VoidCallback callback,
    required this.options,
    ErrorCallback? onError,
  })  : _onError = onError,
        name = options.name!,
        _callback = callback;

  /// The name of the effect, useful for logging purposes.
  final String name;

  /// The callback that is fired each time a signal updates.
  final VoidCallback _callback;

  /// Optionally handle the error case
  final ErrorCallback? _onError;

  @override
  SolidartCaughtException? _errorValue;

  /// {@macro effect-options}
  final EffectOptions options;

  bool _disposed = false;
  bool _isRunning = false;

  @override
  bool get disposed => _disposed;

  @override
  void _run() {
    _isRunning = true;
    final prevSub = system.activeSub;
    system.activeSub = this;
    system.startTracking(this);
    try {
      _callback();
    } on Object catch (e, s) {
      _errorValue = SolidartCaughtException(e, stackTrace: s);
      if (_onError != null) {
        _onError!.call(e);
      } else {
        rethrow;
      }
    } finally {
      system.activeSub = prevSub;
      system.endTracking(this);
      _isRunning = false;
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

    if (_isRunning) return;

    // ignore: cascade_invocations
    system.disposeSub(this);
  }

  @override
  int flags = alien.SubscriberFlags.effect;
}
