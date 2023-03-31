import 'package:solidart/src/core/signal_base.dart';
import 'package:solidart/src/utils.dart';

/// {@macro effect}
Effect<T> createEffect<T>(
  void Function() callback, {
  required List<SignalBase<T>> signals,

  /// whether to fire immediately the callback, defaults to false.
  bool fireImmediately = false,
}) {
  return Effect(
    signals: signals,
    callback: callback,
    fireImmediately: fireImmediately,
  );
}

/// The state of the effect
enum EffectState {
  /// The effect is running, this is the default state
  running,

  /// The effect is paused
  paused,

  /// The effect is resumed
  resumed,

  /// The effect has been cancelled, the last possibile state
  cancelled,
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
class Effect<T> {
  /// {@macro effect}
  Effect({
    required this.signals,
    required this.callback,
    this.fireImmediately = false,
  }) : assert(signals.isNotEmpty, 'You should provide at least one signal') {
    _run();

    // fire immediately the listener.
    if (fireImmediately) _listener();
  }

  /// The list of signals the effect is going to subscribe.
  final List<SignalBase<T>> signals;

  /// The callback that is fired each time a signal updates.
  final VoidCallback callback;

  /// Whether to fire immediately the [callback], defaults to false.
  final bool fireImmediately;

  /// The current state of the effect.
  late EffectState state;

  /// Indicates if the effect is cancelled.
  bool get isCancelled => state == EffectState.cancelled;

  /// Indicates if the effect is running.
  bool get isRunning => state == EffectState.running;

  /// Indicates if the effect is paused.
  bool get isPaused => state == EffectState.paused;

  /// Indicates if the effect is resumed.
  bool get isResumed => state == EffectState.resumed;

  void _listener() {
    callback();
  }

  void _startListeningToSignal(SignalBase<T> signal) {
    // ignore disposed signals.
    if (signal.disposed) return;
    signal.addListener(_listener);
  }

  void _stopListeningToSignal(SignalBase<T> signal) {
    signal.removeListener(_listener);

    // cancel the effect when all the signals are disposed.
    if (_allSignalsDisposed()) {
      state = EffectState.cancelled;
    }
  }

  // Indicates if all the signals are disposed
  bool _allSignalsDisposed() {
    final a = signals.every((signal) => signal.disposed);
    return a;
  }

  void _run() {
    for (final signal in signals) {
      _startListeningToSignal(signal);
      signal.onDispose(() => _stopListeningToSignal(signal));
    }
    state = EffectState.running;
  }

  /// Invalidates the effect.
  ///
  /// After this operation the effect is useless.
  void cancel() {
    signals.forEach(_stopListeningToSignal);
    state = EffectState.cancelled;
  }

  /// Pauses the listening to signals.
  ///
  /// May be followed by a resume later.
  void pause() {
    assert(
      state != EffectState.cancelled,
      'Cannot pause an effect that has been already cancelled',
    );
    signals.forEach(_stopListeningToSignal);
    state = EffectState.paused;
  }

  /// Resumes the listening to signals.
  void resume() {
    assert(
      state == EffectState.paused,
      'Cannot resume an effect that has not been paused',
    );
    signals.forEach(_startListeningToSignal);
    state = EffectState.resumed;
  }
}
