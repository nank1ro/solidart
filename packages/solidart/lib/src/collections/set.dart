import 'dart:collection';

import 'package:solidart/src/_internal/reactive.dart';
import 'package:solidart/src/signal.dart';

// ignore: public_member_api_docs
abstract interface class SetSignal<E> implements Set<E>, Signal<Set<E>> {
  factory SetSignal(Iterable<E> initialValue,
      {bool? autoDispose,
      bool? trackInDevTools,
      bool? trackPreviousValue,
      bool Function(Set<E>?, Set<E>?)? comparator,
      bool? equals,
      String? name}) {
    return _ReactiveSetImpl(Set.from(initialValue),
        autoDispose: autoDispose,
        trackInDevTools: trackInDevTools,
        trackPreviousValue: trackPreviousValue,
        comparator: comparator,
        equals: equals,
        name: name);
  }
}

class _ReactiveSetImpl<E> extends SolidartSignal<Set<E>>
    with SetBase<E>, Reactive<Set<E>>
    implements SetSignal<E> {
  _ReactiveSetImpl(super.initialValue,
      {super.autoDispose,
      super.trackInDevTools,
      super.trackPreviousValue,
      super.comparator,
      super.equals,
      String? name})
      : raw = initialValue,
        super(name: name ?? 'SetSignal');

  Set<E> raw;

  @override
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  set value(Set<E> newValue) {
    raw = newValue;
    super.value = newValue;
  }

  @override
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  bool add(E value) {
    final result = raw.add(value);
    if (result) trigger();
    return result;
  }

  @override
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  bool contains(Object? element) {
    return value.contains(element);
  }

  @override
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  Iterator<E> get iterator => value.iterator;

  @override
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  int get length => value.length;

  @override
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  E? lookup(Object? element) {
    return value.lookup(element);
  }

  @override
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  bool remove(Object? value) {
    final result = raw.remove(value);
    if (result) trigger();
    return result;
  }

  @override
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  Set<E> toSet() => value.toSet();
}
