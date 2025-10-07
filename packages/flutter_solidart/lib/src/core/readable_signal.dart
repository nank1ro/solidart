// coverage:ignore-file
import 'package:flutter_solidart/src/core/value_listenable_signal_mixin.dart';
import 'package:solidart/solidart.dart' as solidart;

/// {@macro readsignal}
class ReadableSignal<T> extends solidart.ReadableSignal<T>
    with ValueListenableSignalMixin<T> {
  /// {@macro readsignal}
  ReadableSignal(
    super.value, {
    super.equals,
    super.name,
    super.autoDispose,
    super.comparator,
    super.trackInDevTools,
    super.trackPreviousValue,
  });

  /// {@macro readsignal}
  ReadableSignal.lazy({
    super.equals,
    super.name,
    super.autoDispose,
    super.comparator,
    super.trackInDevTools,
    super.trackPreviousValue,
  }) : super.lazy();
}
