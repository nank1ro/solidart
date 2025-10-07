// coverage:ignore-file
import 'package:flutter_solidart/src/core/value_listenable_signal_mixin.dart';
import 'package:solidart/solidart.dart' as solidart;

/// {@macro computed}
class Computed<T> extends solidart.Computed<T>
    with ValueListenableSignalMixin<T> {
  /// {@macro computed}
  Computed(
    super.selector, {
    super.equals,
    super.name,
    super.autoDispose,
    super.comparator,
    super.trackInDevTools,
    super.trackPreviousValue,
  });
}
