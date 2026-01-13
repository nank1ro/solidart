import 'package:flutter/foundation.dart';
import 'package:flutter_solidart/src/core/value_listenable_signal_mixin.dart';
import 'package:solidart/solidart.dart' as core;

abstract interface class ReadonlySignal<T> implements ValueListenable<T> {}

class Signal<T> extends core.Signal<T>
    with SignalValueListenableMixin<T>
    implements ReadonlySignal<T> {
  Signal(
    super.initialValue, {
    super.autoDispose,
    super.name,
    super.equals,
    super.trackPreviousValue,
    super.trackInDevTools,
  });

  factory Signal.lazy({
    bool? autoDispose,
    String? name,
    core.ValueComparator<T> equals,
    bool? trackPreviousValue,
    bool? trackInDevTools,
  }) = LazySignal<T>;
}

class LazySignal<T> extends core.LazySignal<T>
    with SignalValueListenableMixin<T>
    implements Signal<T>, ReadonlySignal<T> {
  LazySignal({
    super.autoDispose,
    super.name,
    super.equals,
    super.trackPreviousValue,
    super.trackInDevTools,
  });
}
