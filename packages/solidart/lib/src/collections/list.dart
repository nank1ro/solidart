import 'dart:collection';

import 'package:solidart/src/_internal/reactive.dart';
import 'package:solidart/src/signal.dart';

// ignore: public_member_api_docs
abstract interface class ListSignal<E> implements List<E>, Signal<List<E>> {
  factory ListSignal(List<E> initialValue,
      {bool? autoDispose,
      bool? trackInDevTools,
      bool? trackPreviousValue,
      bool Function(List<E>?, List<E>?)? comparator,
      bool? equals,
      String? name}) = _ReactiveListImpl<E>;
}

class _ReactiveListImpl<E> extends SolidartSignal<List<E>>
    with ListBase<E>, Reactive<List<E>>
    implements ListSignal<E> {
  _ReactiveListImpl(super.initialValue,
      {super.autoDispose,
      super.trackInDevTools,
      super.trackPreviousValue,
      super.comparator,
      super.equals,
      String? name})
      : raw = initialValue,
        super(name: name ?? 'ListSignal');

  List<E> raw;

  @override
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  set value(List<E> newValue) {
    raw = newValue;
    super.value = newValue;
  }

  @override
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  int get length => value.length;

  @override
  set length(int newLength) {
    if (raw.length != newLength) {
      raw.length = newLength;
      trigger();
    }
  }

  @override
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  E operator [](int index) => value[index];

  @override
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  void operator []=(int index, E value) {
    raw[index] = value;
    trigger();
  }

  @override
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  void add(E element) {
    raw.add(element);
    trigger();
  }
}
