import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:flutter_solidart/src/core/value_listenable_signal_mixin.dart';
import 'package:solidart/solidart.dart' as core;

class Resource<T> extends core.Resource<T>
    with SignalValueListenableMixin<core.ResourceState<T>>
    implements ReadonlySignal<ResourceState<T>> {
  Resource(
    super.fetcher, {
    super.source,
    super.lazy,
    super.useRefreshing,
    super.trackPreviousState,
    super.debounceDelay,
    super.autoDispose,
    super.name,
    super.trackInDevTools,
    super.equals,
  });

  Resource.stream(
    super.stream, {
    super.source,
    super.lazy,
    super.useRefreshing,
    super.trackPreviousState,
    super.debounceDelay,
    super.autoDispose,
    super.name,
    super.trackInDevTools,
    super.equals,
  }) : super.stream();
}
