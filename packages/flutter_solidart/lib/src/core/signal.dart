import 'package:flutter/foundation.dart';
import 'package:flutter_solidart/src/core/value_listenable_signal_mixin.dart';
import 'package:solidart/solidart.dart' as core;

/// A Solidart [core.ReadonlySignal] that is also a Flutter [ValueListenable].
abstract interface class ReadonlySignal<T>
    implements core.ReadonlySignal<T>, ValueListenable<T> {}

/// A Solidart [core.Signal] that is also a Flutter [ValueListenable].
class Signal<T> extends core.Signal<T>
    with SignalValueListenableMixin<T>
    implements ReadonlySignal<T> {
  /// Creates a new [Signal] and exposes it as a [ValueListenable].
  Signal(
    super.initialValue, {
    super.autoDispose,
    super.name,
    super.equals,
    super.trackPreviousValue,
    super.trackInDevTools,
  });

  /// Creates a lazy [Signal] and exposes it as a [ValueListenable].
  factory Signal.lazy({
    bool? autoDispose,
    String? name,
    core.ValueComparator<T> equals,
    bool? trackPreviousValue,
    bool? trackInDevTools,
  }) = LazySignal<T>;
}

/// A lazy [Signal] that is also a Flutter [ValueListenable].
class LazySignal<T> extends core.LazySignal<T>
    with SignalValueListenableMixin<T>
    implements Signal<T>, ReadonlySignal<T> {
  /// Creates a lazy [Signal] and exposes it as a [ValueListenable].
  LazySignal({
    super.autoDispose,
    super.name,
    super.equals,
    super.trackPreviousValue,
    super.trackInDevTools,
  });
}

/// A Solidart [core.ListSignal] that is also a Flutter [ValueListenable].
class ListSignal<E> extends core.ListSignal<E>
    with SignalValueListenableMixin<List<E>>
    implements ReadonlySignal<List<E>> {
  /// Creates a new [ListSignal] and exposes it as a [ValueListenable].
  ListSignal(
    super.initialValue, {
    super.autoDispose,
    super.name,
    super.equals,
    super.trackPreviousValue,
    super.trackInDevTools,
  });
}

/// A Solidart [core.SetSignal] that is also a Flutter [ValueListenable].
class SetSignal<E> extends core.SetSignal<E>
    with SignalValueListenableMixin<Set<E>>
    implements ReadonlySignal<Set<E>> {
  /// Creates a new [SetSignal] and exposes it as a [ValueListenable].
  SetSignal(
    super.initialValue, {
    super.autoDispose,
    super.name,
    super.equals,
    super.trackPreviousValue,
    super.trackInDevTools,
  });
}

/// A Solidart [core.MapSignal] that is also a Flutter [ValueListenable].
class MapSignal<K, V> extends core.MapSignal<K, V>
    with SignalValueListenableMixin<Map<K, V>>
    implements ReadonlySignal<Map<K, V>> {
  /// Creates a new [MapSignal] and exposes it as a [ValueListenable].
  MapSignal(
    super.initialValue, {
    super.autoDispose,
    super.name,
    super.equals,
    super.trackPreviousValue,
    super.trackInDevTools,
  });
}
