import 'package:flutter_solidart/src/core/value_notifier_signal_mixin.dart';
import 'package:solidart/solidart.dart' as solidart;

/// {@macro set-signal}
class SetSignal<T> extends solidart.SetSignal<T>
    with ValueNotifierSignalMixin<Set<T>> {
  /// {@macro set-signal}
  SetSignal(
    super.initialValue, {
    super.equals,
    super.name,
    super.autoDispose,
    super.comparator,
    super.trackInDevTools,
    super.trackPreviousValue,
  });
}
