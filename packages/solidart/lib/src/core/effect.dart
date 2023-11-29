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
  const EffectOptions({this.name, this.delay});

  /// The name of the effect, useful for logging
  final String? name;

  /// Delay each effect reaction
  final Duration? delay;
}

// coverage:ignore-start

/// {@macro effect}
@Deprecated('Use Effect instead')
DisposeEffect createEffect(
  void Function(DisposeEffect dispose) callback, {
  ErrorCallback? onError,
  EffectOptions options = const EffectOptions(),
}) {
  return Effect(callback, onError: onError, options: options).dispose;
}
// coverage:ignore-end

/// The reaction interface
abstract class ReactionInterface implements Derivation {
  /// Indicate if the reaction is dispose
  bool get disposed;

  /// Disposes the reaction
  void dispose();

  /// Runs the reaction
  void run();
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
    @Deprecated('Use Effect instead')
    void Function(DisposeEffect dispose) callback, {
    ErrorCallback? onError,
    EffectOptions options = const EffectOptions(),
  }) {
    late Effect effect;

    if (options.delay == null) {
      effect = Effect._internal(
        callback: () => effect.track(() => callback(effect.dispose)),
        onError: onError,
        options: options,
      );
    } else {
      final scheduler = createDelayedScheduler(options.delay!);
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
                effect.track(() => callback(effect.dispose));
              } else {
                // coverage:ignore-start
                timer?.cancel();
                // coverage:ignore-end
              }
            });
          }
        },
        options: options,
        onError: onError,
      );
    }
    // ignore: cascade_invocations
    effect.schedule();
    return effect;
  }

  /// {@macro effect}
  Effect._internal({
    required VoidCallback callback,
    EffectOptions? options,
    ErrorCallback? onError,
  })  : _onError = onError,
        name = options?.name ?? ReactiveContext.main.nameFor('Effect'),
        _callback = callback;

  /// The name of the effect, useful for logging purposes.
  final String name;

  /// The callback that is fired each time a signal updates.
  final VoidCallback _callback;

  /// Optionally handle the error case
  final ErrorCallback? _onError;

  final _context = ReactiveContext.main;
  bool _isScheduled = false;
  bool _disposed = false;
  bool _isRunning = false;

  @override
  // ignore: prefer_final_fields
  DerivationState _dependenciesState = DerivationState.notTracking;

  @override
  SolidartCaughtException? _errorValue;

  @override
  Set<Atom>? _newObservables;

  @override
  bool get disposed => _disposed;

  final Set<Atom> __observables = {};

  @override
  // ignore: prefer_final_fields
  Set<Atom> get _observables => __observables;

  @override
  set _observables(Set<Atom> newObservables) {
    // dispose when all observables are no longer being observed
    if (newObservables.every((ob) => ob.disposed)) {
      dispose();
    } else {
      __observables
        ..clear()
        ..addAll(newObservables);
    }
  }

  @override
  void _onBecomeStale() {
    schedule();
  }

  // ignore: public_member_api_docs
  void schedule() {
    if (_isScheduled) {
      return;
    }

    _isScheduled = true;
    _context
      ..addPendingReaction(this)
      ..runReactions();
  }

  // ignore: public_member_api_docs
  void track(void Function() fn) {
    _context.startBatch();

    _isRunning = true;
    _context.trackDerivation(this, fn);
    _isRunning = false;

    if (_disposed) {
      _context.clearObservables(this);
    }

    if (_context.hasCaughtException(this)) {
      if (_onError != null) {
        _onError!.call(_errorValue!);
      }
      // coverage:ignore-start
      else {
        throw _errorValue!;
      }
      // coverage:ignore-end
    }

    _context.endBatch();
  }

  @override
  void run() {
    if (_disposed) return;

    _context.startBatch();

    _isScheduled = false;

    if (_context.shouldCompute(this)) {
      try {
        _callback();
      } on Object catch (e, s) {
        // coverage:ignore-start
        // Note: "on Object" accounts for both Error and Exception
        _errorValue = SolidartCaughtException(e, stackTrace: s);
        if (_onError != null) {
          _onError!.call(_errorValue!);
        } else {
          throw _errorValue!;
        }
        // coverage:ignore-end
      }
    }

    _context.endBatch();
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
    _context
      ..startBatch()
      ..clearObservables(this)
      ..endBatch();
  }
}
