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
    return _MapImpl<K, V>(reactive: reactive);
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
  const _MapImpl({required this.reactive});

  final _ReactiveImpl<K, V> reactive;

  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  Map<K, V> get raw => reactive.latestValue!;

  @override
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  V? operator [](Object? key) => value[key];

  @override
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  void operator []=(K key, V value) {
    raw[key] = value;
    reactive.trigger();
  }

  @override
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  void clear() {
    raw.clear();
    reactive.trigger();
  }

  @override
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  Iterable<K> get keys => value.keys;

  @override
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  V? remove(Object? key) {
    final result = raw.remove(key);
    reactive.trigger();
    return result;
  }

  @override
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  bool get autoDispose => reactive.autoDispose;

  @override
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  bool Function(Map<K, V>?, Map<K, V>?) get comparator => reactive.comparator;

  @override
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  void dispose() => reactive.dispose();

  @override
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  bool get disposed => reactive.disposed;

  @override
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  bool get equals => reactive.equals;

  @override
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  bool get hasPreviousValue => reactive.hasPreviousValue;

  @override
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  bool get hasValue => reactive.hasValue;

  @override
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  int get listenerCount => reactive.listenerCount;

  @override
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  String get name => reactive.name;

  @override
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  void onDispose(void Function() callback) {
    reactive.onDispose(callback);
  }

  @override
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  Map<K, V>? get previousValue => reactive.previousValue;

  @override
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  bool get trackInDevTools => reactive.trackInDevTools;

  @override
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  bool get trackPreviousValue => reactive.trackPreviousValue;

  @override
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  Map<K, V>? get untrackedPreviousValue => reactive.untrackedPreviousValue;

  @override
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  Map<K, V> get untrackedValue => reactive.untrackedValue;

  @override
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  Map<K, V> get value => reactive.value;
}
