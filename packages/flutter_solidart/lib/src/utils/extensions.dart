import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

/// {@template signal-to-value-notifier}
/// Converts a [SignalBase] into a [ValueNotifier];
/// {@endtemplate}
extension SignalToValueNotifier<T> on SignalBase<T> {
  /// {@macro signal-to-value-notifier}
  ValueNotifier<T> toValueNotifier() {
    final notifier = ValueNotifier(value);
    final unobserve = Effect((_) => notifier.value = value);
    onDispose(unobserve.call);
    return notifier;
  }
}

/// {@template value-notifier-to-signal}
/// Converts a [ValueNotifier] into a [Signal];
/// {@endtemplate}
extension ValueNotifierToSignal<T> on ValueNotifier<T> {
  /// {@macro value-notifier-to-signal}
  Signal<T> toSignal() {
    final signal = Signal(value, options: SignalOptions<T>(equals: true));
    void setValue() => signal.set(value);
    addListener(setValue);
    signal.onDispose(() => removeListener(setValue));
    return signal;
  }
}
