import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

/// {@template signal-to-value-notifier}
/// Converts a [ReadableSignal] into a [ValueNotifier];
/// {@endtemplate}
extension SignalToValueNotifier<T> on ReadableSignal<T> {
  /// {@macro signal-to-value-notifier}
  ValueNotifier<T> toValueNotifier() {
    final notifier = ValueNotifier(value);
    // final unobserve =
    Effect((_) => notifier.value = value);
    // onDispose(unobserve.call); // TODO
    return notifier;
  }
}

/// {@template value-notifier-to-signal}
/// Converts a [ValueNotifier] into a [Signal];
/// {@endtemplate}
extension ValueNotifierToSignal<T> on ValueNotifier<T> {
  /// {@macro value-notifier-to-signal}
  Signal<T> toSignal({
    /// {macro SignalBase.name}
    String? name,

    /// {macro SignalBase.autoDispose}
    bool? autoDispose,

    /// {macro SignalBase.trackInDevTools}
    // bool? trackInDevTools,
  }) {
    final signal = Signal(
      value,
      equals: true,
      name: name ?? 'ValueNotifier<$T>',
      // autoDispose: autoDispose,
      // trackInDevTools: trackInDevTools,
    );

    void setValue() => signal.set(value);
    addListener(setValue);
    // signal.onDispose(() => removeListener(setValue)); // TODO
    return signal;
  }
}
