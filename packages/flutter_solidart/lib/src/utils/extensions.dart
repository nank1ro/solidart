import 'package:flutter/foundation.dart';
import 'package:solidart/solidart.dart';

/// {@template readonly-signal-to-value-notifier}
/// Converts a [ReadonlySignal] into a [ValueNotifier].
///
/// The returned notifier stays in sync with the signal and disposes its
/// internal effect when the notifier or the signal is disposed.
/// {@endtemplate}
extension ReadonlySignalToValueNotifier<T> on ReadonlySignal<T> {
  /// {@macro readonly-signal-to-value-notifier}
  ValueNotifier<T> toValueNotifier() => _SignalValueNotifier(this);
}

class _SignalValueNotifier<T> extends ValueNotifier<T> {
  _SignalValueNotifier(this._signal) : super(_signal.value) {
    _effect = Effect(
      () => value = _signal.value,
      autoDispose: false,
      detach: true,
    );
    _signal.onDispose(_effect.dispose);
  }

  final ReadonlySignal<T> _signal;
  late final Effect _effect;

  @override
  void dispose() {
    _effect.dispose();
    super.dispose();
  }
}

/// {@template value-listenable-to-signal}
/// Converts a [ValueListenable] into a [Signal] that mirrors its value.
///
/// Updates flow from the [ValueListenable] into the signal. Disposing the
/// signal removes the listener.
/// {@endtemplate}
extension ValueListenableToSignal<T> on ValueListenable<T> {
  /// {@macro value-listenable-to-signal}
  Signal<T> toSignal({
    String? name,
    bool? autoDispose,
    bool? trackPreviousValue,
    bool? trackInDevTools,
    ValueComparator<T> equals = identical,
  }) {
    final signal = Signal(
      value,
      name: name,
      autoDispose: autoDispose,
      trackPreviousValue: trackPreviousValue,
      trackInDevTools: trackInDevTools,
      equals: equals,
    );

    void sync() => signal.value = value;
    addListener(sync);
    signal.onDispose(() => removeListener(sync));
    return signal;
  }
}
