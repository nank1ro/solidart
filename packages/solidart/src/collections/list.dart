import 'dart:collection';

import '../core/signal.dart';
import '_reactive.dart';

abstract interface class ReactiveList<E> implements Signal<List<E>>, List<E> {
  factory ReactiveList(Iterable<E> initialValue, {bool? autoDispose}) =
      SolidartReactiveList<E>;
}

class SolidartReactiveList<E> extends SolidartSignal<List<E>>
    with ListBase<E>, Reactive<List<E>>
    implements ReactiveList<E> {
  SolidartReactiveList(Iterable<E> initialValue, {super.autoDispose})
      : super(List.from(initialValue));

  @override
  int get length => value.length;

  set length(int newLength) {
    if (latestValue!.length == newLength) return;
    latestValue!.length = newLength;
    trigger();
  }

  @override
  E operator [](int index) => value[index];

  @override
  void operator []=(int index, E value) {
    latestValue![index] = value;
    trigger();
  }

  @override
  void add(E element) {
    latestValue!.add(element);
    trigger();
  }
}
