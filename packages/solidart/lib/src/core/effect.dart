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

/// The reaction interface
abstract class ReactionInterface implements Derivation {
  /// Indicate if the reaction is dispose
  bool get disposed;

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
class Effect implements ReactionInterface {
  /// {@macro effect}
  factory Effect(
    void Function(DisposeEffect dispose) callback, {
    ErrorCallback? onError,
    EffectOptions? options,
  }) {
    late Effect effect;
    final name = options?.name ?? ReactiveContext.main.nameFor('Effect');
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
    // ignore: cascade_invocations
    effect._schedule();
    return effect;
  }

  /// {@macro effect}
  Effect._internal({
    required VoidCallback callback,
    required this.options,
    ErrorCallback? onError,
  })  : _onError = onError,
        name = options.name!,
        _callback = callback,
        _internalEffect = alien.Effect(callback);

  /// The name of the effect, useful for logging purposes.
  final String name;

  /// The callback that is fired each time a signal updates.
  final VoidCallback _callback;

  /// Optionally handle the error case
  final ErrorCallback? _onError;

  /// {@macro effect-options}
  final EffectOptions options;

  bool _disposed = false;
  bool _isRunning = false;

  late final alien.Effect<void> _internalEffect;

  @override
  bool get disposed => _disposed;

  final Set __observables = {};

  // The list of dependencies which the dispose has been prevented.
  final Set _observablesDisposePrevented = {};

  void _schedule() {
    try {
      _internalEffect.run();
    } catch (e, s) {
      _onError?.call(SolidartCaughtException(e, stackTrace: s));
    }
  }

  /// Tracks the observables present in the given [fn] function
  ///
  /// This method must not be used directly.
  @protected
  void track(void Function() fn, {bool preventDisposal = false}) {
    _isRunning = true;
    _internalEffect.run();
    _isRunning = false;

    // coverage:ignore-start
    if (preventDisposal) {
      for (final ob in __observables) {
        ob._disposable = false;
        _observablesDisposePrevented.add(ob);
      }
    }
    // coverage:ignore-end
    // _context.endBatch();
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

    // coverage:ignore-start
    for (final ob in _observablesDisposePrevented) {
      ob
        .._disposable = true
        .._mayDispose();
    }
    // coverage:ignore-end
    __observables.clear();
  }

  @override
  void _mayDispose() {
    if (options.autoDispose) {
      dispose();
    }
  }
}
