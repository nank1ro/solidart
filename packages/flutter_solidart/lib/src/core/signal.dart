import 'package:flutter_solidart/src/core/readable_signal.dart';
import 'package:flutter_solidart/src/core/value_notifier_signal_mixin.dart';
import 'package:solidart/solidart.dart' as solidart;

/// {@macro signal}
class Signal<T> extends solidart.Signal<T> with ValueNotifierSignalMixin<T> {
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

  @override
  ReadableSignal<T> toReadSignal() {
    return ReadableSignal(
      value,
      equals: equals,
      name: name,
      autoDispose: autoDispose,
      comparator: comparator,
      trackInDevTools: trackInDevTools,
      trackPreviousValue: trackPreviousValue,
    );
  }
}
