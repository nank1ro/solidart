import 'package:flutter/foundation.dart';
import 'package:flutter_solidart/src/core/value_listenable_signal_mixin.dart';
import 'package:solidart/solidart.dart' as core;

/// A Solidart [core.Resource] that is also a Flutter [ValueListenable].
class Resource<T> extends core.Resource<T>
    with SignalValueListenableMixin<core.ResourceState<T>> {
  /// Creates a new [Resource] and exposes it as a [ValueListenable].
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

  /// Creates a stream-based [Resource] and exposes it as a [ValueListenable].
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
