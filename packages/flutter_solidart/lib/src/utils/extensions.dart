import 'package:flutter/foundation.dart';
import 'package:flutter_solidart/src/core/signal.dart';
import 'package:solidart/solidart.dart' as core;

/// {@template readonly-signal-to-value-notifier}
/// Converts a [core.ReadonlySignal] into a [ValueNotifier].
///
/// The returned notifier stays in sync with the signal and disposes its
/// internal effect when the notifier or the signal is disposed.
/// {@endtemplate}
extension ReadonlySignalToValueNotifier<T> on core.ReadonlySignal<T> {
  /// {@macro readonly-signal-to-value-notifier}
  ValueNotifier<T> toValueNotifier() => _SignalValueNotifier(this);
}

class _SignalValueNotifier<T> extends ValueNotifier<T> {
  _SignalValueNotifier(this._signal) : super(_readValue(_signal)) {
    _effect = core.Effect(
      () => value = _readValue(_signal),
      autoDispose: false,
      detach: true,
    );
    _signal.onDispose(_effect.dispose);
  }

  final core.ReadonlySignal<T> _signal;
  late final core.Effect _effect;

  @override
  void dispose() {
    _effect.dispose();
    super.dispose();
  }
}

T _readValue<T>(core.ReadonlySignal<T> signal) {
  if (signal is core.Resource) {
    return (signal as core.Resource).state as T;
  }
  return signal.value;
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
    core.ValueComparator<T> equals = identical,
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
