import 'package:flutter_solidart/src/core/value_notifier_signal_mixin.dart';
import 'package:solidart/solidart.dart' as solidart;

/// {@macro resource}
class Resource<T> extends solidart.Resource<T>
    with ValueNotifierSignalMixin<solidart.ResourceState<T>> {
  /// {@macro resource}
  Resource(
    super.fetcher, {
    super.equals,
    super.name,
    super.autoDispose,
    super.lazy,
    super.trackInDevTools,
    super.useRefreshing,
    super.debounceDelay,
    super.source,
    super.trackPreviousState,
  });

  /// {@macro resource}
  Resource.stream(
    super.stream, {
    super.equals,
    super.name,
    super.autoDispose,
    super.lazy,
    super.trackInDevTools,
    super.useRefreshing,
    super.debounceDelay,
    super.source,
    super.trackPreviousState,
  }) : super.stream();
}
