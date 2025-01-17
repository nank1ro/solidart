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
abstract class ReactionInterface {
  /// Indicate if the reaction is dispose
  bool get disposed;

  /// Tries to dispose the effects, if no listeners are present
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
/// signals values, unless you specify otherwise with the `fireImmediately`
///
/// > An effect is useless after it is disposed, you must not use it anymore.
/// {@endtemplate}
class Effect implements ReactionInterface {
  /// {@macro effect}
  factory Effect(
    void Function(DisposeEffect dispose) callback, {
    ErrorCallback? onError,
    EffectOptions? options,

    /// {@macro Effect.fireImmediately}
    bool? fireImmediately,
  }) {
    late Effect effect;
    final name = options?.name ?? ReactiveName.nameFor('Effect');
    final effectiveFireImmediately =
        fireImmediately ?? SolidartConfig.fireEffectImmediately;
    final effectiveOptions = (options ?? EffectOptions()).copyWith(name: name);
    if (effectiveOptions.delay == null) {
      effect = Effect._internal(
        fireImmediately: effectiveFireImmediately,
        callback: () => callback(effect.dispose),
        onError: onError,
        options: effectiveOptions,
      );
    } else {
      final scheduler = createDelayedScheduler(effectiveOptions.delay!);
      var isScheduled = false;
      Timer? timer;

      effect = Effect._internal(
        fireImmediately: effectiveFireImmediately,
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
    if (effectiveFireImmediately) {
      effect._schedule();
    }
    return effect;
  }

  /// {@macro effect}
  Effect._internal({
    required VoidCallback callback,
    required this.options,

    /// {@macro Effect.fireImmediately}
    required this.fireImmediately,
    ErrorCallback? onError,
  })  : _onError = onError,
        name = options.name! {
    _internalEffect = _AlienEffect(callback, parent: this);
  }

  /// The name of the effect, useful for logging purposes.
  final String name;

  /// Optionally handle the error case
  final ErrorCallback? _onError;

  /// {@macro effect-options}
  final EffectOptions options;

  /// {@template Effect.fireImmediately}
  /// {@macro fire-effect-immediately}
  ///
  /// If a value is not provided, defaults to
  /// [SolidartConfig.fireEffectImmediately].
  /// {@endtemplate}
  final bool fireImmediately;

  bool _disposed = false;

  late final alien.Effect<void> _internalEffect;

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
      Future.microtask(_mayDispose);
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
    print('dispose Effect');
    if (_disposed) return;
    _disposed = true;

    _internalEffect.stop();

    for (final dep in _deps) {
      print('call dispose on dep $dep');
      print('dep runtimeType ${dep.runtimeType}');
      if (dep is _AlienSignal) dep.parent._mayDispose();
      if (dep is _AlienComputed) dep.parent._mayDispose();
    }

    _deps.clear();
  }

  @override
  void _mayDispose() {
    if (!options.autoDispose || _disposed) return;
    print('effect deps ${_internalEffect.deps}');
    print('dep ${_internalEffect.deps?.dep}');
    if (_internalEffect.deps == null) {
      dispose();
    } else if (_internalEffect.deps?.dep != null) {
      _deps.clear();

      var link = _internalEffect.deps;
      for (; link != null; link = link.nextDep) {
        final dep = link.dep;
        if (dep == null) break;
        _deps.add(dep);
      }
      print('effects deps $_deps');
    }
  }
}
