import 'package:solidart/src/core/signal_base.dart';
import 'package:solidart/src/utils.dart';

/// Creates a reactive computation.
///
/// An _effect_ is an observer; it runs a side effect that depends on signals.
///
/// The effect subscribes to the [signals] provided and reruns when any of them
/// change.
///
/// The effect will be automatically invalidated when all the [signals] dispose.
/// But you can manually invalidate an effect using the [Effect.cancel] method.
///
/// You may also [Effect.pause] and [Effect.resume] an effect if you want to
/// ignore values for some time.
Effect<T> createEffect<T>(
  void Function() callback, {
  required List<SignalBase<T>> signals,

  /// whether to fire immediatly the callback, defaults to false.
  bool fireImmediatly = false,
}) {
  return Effect(
    signals: signals,
    callback: callback,
    fireImmediatly: fireImmediatly,
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

/// A side effect that react to any change of the [signals] provided by calling
/// [callback] every time.
class Effect<T> {
  Effect({
    required this.signals,
    required this.callback,
    this.fireImmediatly = false,
  }) : assert(signals.isNotEmpty, 'You should provide at least one signal') {
    _run();

    // fire immediatly the listener.
    if (fireImmediatly) _listener();
  }

  /// The list of signals the effect is going to subscribe.
  final List<SignalBase<T>> signals;

  /// The callback that is fired each time a signal updates.
  final VoidCallback callback;

  /// Whether to fire immediatly the [callback], defaults to false.
  final bool fireImmediatly;

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
