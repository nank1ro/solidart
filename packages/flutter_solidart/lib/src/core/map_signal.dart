import 'package:flutter_solidart/src/core/value_notifier_signal_mixin.dart';
import 'package:solidart/solidart.dart' as solidart;

/// {@macro map-signal}
class MapSignal<K, V> extends solidart.MapSignal<K, V>
    with ValueNotifierSignalMixin<Map<K, V>> {
  /// {@macro map-signal}
  MapSignal(
    super.initialValue, {
    super.equals,
    super.name,
    super.autoDispose,
    super.comparator,
    super.trackInDevTools,
    super.trackPreviousValue,
  });
}
