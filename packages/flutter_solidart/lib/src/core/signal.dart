import 'package:flutter_solidart/src/core/readable_signal.dart';
import 'package:flutter_solidart/src/core/value_notifier_signal_mixin.dart';

/// Adds the [toggle] method to boolean signals
extension ToggleBoolSignal on Signal<bool> {
  /// Toggles the signal boolean value.
  void toggle() => value = !value;
}

/// {@macro signal}
class Signal<T> extends ReadableSignal<T> with ValueNotifierSignalMixin<T> {
  /// {@macro signal}
  Signal(
    super.value, {
    super.equals,
    super.name,
    super.autoDispose,
    super.comparator,
    super.trackInDevTools,
    super.trackPreviousValue,
  });

  /// {@macro signal}
  Signal.lazy({
    super.equals,
    super.name,
    super.autoDispose,
    super.comparator,
    super.trackInDevTools,
    super.trackPreviousValue,
  }) : super.lazy();

  /// {@macro set-signal-value}
  @override
  set value(T newValue) {
    setValue(newValue);
  }

  /// Calls a function with the current value and assigns the result as the
  /// new value.
  T updateValue(T Function(T value) callback) =>
      value = callback(untrackedValue);

  /// Converts this [Signal] into a [ReadableSignal]
  /// Use this method to remove the visility to the value setter.
  ReadableSignal<T> toReadSignal() => this;
}
