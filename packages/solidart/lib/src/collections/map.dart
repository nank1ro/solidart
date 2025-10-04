import 'dart:collection';

import 'package:solidart/src/_internal/reactive.dart';
import 'package:solidart/src/signal.dart';

// ignore: public_member_api_docs
abstract interface class MapSignal<K, V>
    implements Map<K, V>, ReadonlySignal<Map<K, V>> {
  factory MapSignal(Map<K, V> initialValue,
      {bool? autoDispose,
      bool? trackInDevTools,
      bool? trackPreviousValue,
      bool Function(Map<K, V>?, Map<K, V>?)? comparator,
      bool? equals,
      String? name}) {
    final reactive = _ReactiveImpl<K, V>(
      initialValue,
      autoDispose: autoDispose,
      trackInDevTools: trackInDevTools,
      trackPreviousValue: trackPreviousValue,
      comparator: comparator,
      equals: equals,
      name: name,
    );
    return _MapImpl<K, V>(reactive: reactive, raw: initialValue);
  }
}

class _ReactiveImpl<K, V> extends SolidartSignal<Map<K, V>>
    with Reactive<Map<K, V>> {
  _ReactiveImpl(super.initialValue,
      {super.autoDispose,
      super.trackInDevTools,
      super.trackPreviousValue,
      super.comparator,
      super.equals,
      String? name})
      : super(name: name ?? 'MapSignal');
}

class _MapImpl<K, V> with MapBase<K, V> implements MapSignal<K, V> {
  const _MapImpl({required this.reactive, required this.raw});

  final _ReactiveImpl<K, V> reactive;
  final Map<K, V> raw;

  @override
  V? operator [](Object? key) => value[key];

  @override
  void operator []=(K key, V value) {
    raw[key] = value;
    reactive.trigger();
  }

  @override
  void clear() {
    raw.clear();
    reactive.trigger();
  }

  @override
  Iterable<K> get keys => value.keys;

  @override
  V? remove(Object? key) {
    final result = raw.remove(key);
    reactive.trigger();
    return result;
  }

  @override
  bool get autoDispose => reactive.autoDispose;

  @override
  bool Function(Map<K, V>?, Map<K, V>?) get comparator => reactive.comparator;

  @override
  void dispose() => reactive.dispose();

  @override
  bool get disposed => reactive.disposed;

  @override
  bool get equals => reactive.equals;

  @override
  bool get hasPreviousValue => reactive.hasPreviousValue;

  @override
  bool get hasValue => reactive.hasValue;

  @override
  int get listenerCount => reactive.listenerCount;

  @override
  String get name => reactive.name;

  @override
  void onDispose(void Function() callback) {
    reactive.onDispose(callback);
  }

  @override
  Map<K, V>? get previousValue => reactive.previousValue;

  @override
  bool get trackInDevTools => reactive.trackInDevTools;

  @override
  bool get trackPreviousValue => reactive.trackPreviousValue;

  @override
  Map<K, V>? get untrackedPreviousValue => reactive.untrackedPreviousValue;

  @override
  Map<K, V> get untrackedValue => reactive.untrackedValue;

  @override
  Map<K, V> get value => reactive.value;
}
