import 'dart:async';

import 'package:meta/meta.dart';
import 'package:solidart/src/core/atom.dart';
import 'package:solidart/src/core/derivation.dart';
import 'package:solidart/src/core/reactive_context.dart';
import 'package:solidart/src/utils.dart';

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

/// {@macro effect}
DisposeEffect createEffect(
  void Function(DisposeEffect dispose) callback, {
  ErrorCallback? onError,
  EffectOptions options = const EffectOptions(),
}) {
  late Effect effect;

  if (options.delay == null) {
    effect = Effect(
      callback: () => effect.track(() => callback(effect.dispose)),
      onError: onError,
      options: options,
    );
  } else {
    final scheduler = createDelayedScheduler(options.delay!);
    var isScheduled = false;
    Timer? timer;

    effect = Effect(
      callback: () {
        if (!isScheduled) {
          isScheduled = true;

          timer?.cancel();
          timer = null;

          timer = scheduler(() {
            isScheduled = false;
            if (!effect.isDisposed) {
              effect.track(() => callback(effect.dispose));
            } else {
              timer?.cancel();
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
  return effect.dispose;
}

/// The reaction interface
abstract class ReactionInterface implements Derivation {
  /// Indicate if the reaction is dispose
  bool get isDisposed;

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
/// An effect can be created by using `createEffect`.
/// The effect subscribes to any signal provided in the signals array and
/// reruns when any of them change.
///
/// So let's create an `Effect` that reruns whenever `counter` changes:
/// ```dart
/// // sample signal
/// final counter = createSignal(0);
///
/// // effect creation
/// createEffect(() {
///     print("The count is now ${counter.value}");
/// }, signals: [counter]);
///
/// // increment the counter
/// counter.value++;
///
/// // The effect prints `The count is now 1`;
/// ```
///
/// > The effect automatically cancels when all the `signals` provided dispose
///
/// The `createEffect` method returns an `Effect` class giving you a more
/// advanced usage:
/// ```dart
/// final effect = createEffect(() {
///     print("The count is now ${counter.value}");
/// }, signals: [counter], fireImmediately: true);
///
/// print(effect.isRunning); // prints true
///
/// // pause effect
/// effect.pause();
///
/// print(effect.isPaused); // prints true
///
/// // resume effect
/// effect.resume();
///
/// print(effect.isResumed); // prints true
///
/// // cancel effect
/// effect.cancel();
///
/// print(effect.isCancelled); // prints true
/// ```
///
/// The `fireImmediately` flag indicates if the effect should run immediately
/// with the current `signals` values, defaults to false.
///
/// You may want to `pause`, `resume` or `cancel` an effect.
///
/// > An effect is useless after it is cancelled, you must not use it anymore.
/// {@endtemplate}
class Effect implements ReactionInterface {
  /// {@macro effect}
  Effect({
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
  bool _isDisposed = false;
  bool _isRunning = false;

  @override
  DerivationState dependenciesState = DerivationState.notTracking;

  @override
  SolidartCaughtException? errorValue;

  @override
  Set<Atom>? newObservables;

  @override
  Set<Atom> observables = {};

  @override
  bool get isDisposed => _isDisposed;

  @override
  void onBecomeStale() {
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

    if (_isDisposed) {
      _context.clearObservables(this);
    }

    if (_context.hasCaughtException(this)) {
      if (_onError != null) {
        _onError!.call(errorValue!);
      } else {
        throw errorValue!;
      }
    }

    _context.endBatch();
  }

  @override
  void run() {
    if (_isDisposed) return;

    _context.startBatch();

    _isScheduled = false;

    if (_context.shouldCompute(this)) {
      try {
        _callback();
      } on Object catch (e, s) {
        // Note: "on Object" accounts for both Error and Exception
        errorValue = SolidartCaughtException(e, stackTrace: s);
        if (_onError != null) {
          _onError!.call(errorValue!);
        } else {
          throw errorValue!;
        }
      }
    }

    _context.endBatch();
  }

  /// No-op
  @override
  void suspend() {}

  /// Invalidates the effect.
  ///
  /// After this operation the effect is useless.
  @override
  void dispose() {
    if (_isDisposed) return;

    _isDisposed = true;

    if (_isRunning) return;

    // ignore: cascade_invocations
    _context
      ..startBatch()
      ..clearObservables(this)
      ..endBatch();
  }
}
