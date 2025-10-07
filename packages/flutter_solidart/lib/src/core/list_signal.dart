// coverage:ignore-file
import 'package:flutter_solidart/src/core/value_notifier_signal_mixin.dart';
import 'package:solidart/solidart.dart' as solidart;

/// {@macro list-signal}
class ListSignal<T> extends solidart.ListSignal<T>
    with ValueNotifierSignalMixin<List<T>> {
  /// {@macro list-signal}
  ListSignal(
    super.initialValue, {
    super.equals,
    super.name,
    super.autoDispose,
    super.comparator,
    super.trackInDevTools,
    super.trackPreviousValue,
  });
}
