// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'package:alien_signals/alien_signals.dart' as alien;
import 'package:alien_signals/system.dart' as alien;
import 'package:solidart/src/_internal/disposable.dart';
import 'package:solidart/src/config.dart';
import 'package:solidart/src/effect.dart';
import 'package:solidart/src/resource/state.dart';
import 'package:solidart/src/signal.dart';
import 'package:solidart/src/until.dart';

part '_resource.impl.dart';

abstract interface class Resource<T>
    implements ReadonlySignal<ResourceState<T>> {
  factory Resource(FutureOr<T> Function() fetcher,
      {ReadonlySignal<dynamic>? source,
      String? name,
      bool? equals,
      bool? autoDispose,
      bool? trackInDevTools,
      bool? lazy,
      bool? useRefreshing,
      bool? trackPreviousState,
      Duration? debounceDelay}) {
    final signal = Signal(ResourceState<T>.loading(),
        autoDispose: autoDispose ?? SolidartConfig.autoDispose,
        name: name ?? 'Resource',
        equals: equals ?? SolidartConfig.equals,
        trackInDevTools: trackInDevTools ?? SolidartConfig.devToolsEnabled,
        trackPreviousValue:
            trackPreviousState ?? SolidartConfig.trackPreviousValue);
    return _ResourceImpl(
        fetcher: fetcher,
        lazy: lazy ?? true,
        useRefreshing: useRefreshing ?? SolidartConfig.useRefreshing,
        debounceDelay: debounceDelay,
        source: source,
        signal: signal);
  }

  factory Resource.stream(Stream<T> Function() stream,
      {ReadonlySignal<dynamic>? source,
      String? name,
      bool? equals,
      bool? autoDispose,
      bool? trackInDevTools,
      bool? lazy,
      bool? useRefreshing,
      bool? trackPreviousState,
      Duration? debounceDelay}) {
    final signal = Signal(ResourceState<T>.loading(),
        autoDispose: autoDispose ?? SolidartConfig.autoDispose,
        name: name ?? 'Resource',
        equals: equals ?? SolidartConfig.equals,
        trackInDevTools: trackInDevTools ?? SolidartConfig.devToolsEnabled,
        trackPreviousValue:
            trackPreviousState ?? SolidartConfig.trackPreviousValue);
    return _ResourceImpl(
        stream: stream,
        lazy: lazy ?? true,
        useRefreshing: useRefreshing ?? SolidartConfig.useRefreshing,
        debounceDelay: debounceDelay,
        source: source,
        signal: signal);
  }

  ResourceState<T> get state;
  ResourceState<T> get untrackedState;
  ResourceState<T>? get previousState;
  ResourceState<T>? get untrackedPreviousState;

  Future<void> refresh();

  FutureOr<T> untilReady();

  ResourceState<T> update(
    ResourceState<T> Function(ResourceState<T> state) callback,
  );
}
