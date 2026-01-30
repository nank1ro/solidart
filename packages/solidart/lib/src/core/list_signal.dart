part of '../solidart.dart';

/// {@template solidart.list-signal}
/// A reactive wrapper around a [List] that copies on write.
///
/// Mutations create a new list instance so that updates are observable:
/// ```dart
/// final list = ListSignal([1, 2]);
/// Effect(() => print(list.length));
/// list.add(3); // triggers effect
/// ```
///
/// Reads (like `length` or index access) establish dependencies; the usual
/// list API is supported.
/// {@endtemplate}
class ListSignal<E> extends Signal<List<E>> with ListMixin<E> {
  /// {@macro solidart.list-signal}
  ///
  /// Creates a reactive list with the provided initial values.
  ListSignal(
    Iterable<E> initialValue, {
    bool? autoDispose,
    String? name,
    ValueComparator<List<E>> equals = identical,
    bool? trackPreviousValue,
    bool? trackInDevTools,
  }) : super(
         List<E>.of(initialValue),
         autoDispose: autoDispose,
         name: name,
         equals: equals,
         trackPreviousValue: trackPreviousValue,
         trackInDevTools: trackInDevTools,
       );

  @override
  int get length => value.length;

  @override
  set length(int newLength) {
    final current = untrackedValue;
    if (current.length == newLength) return;
    value = List<E>.of(current)..length = newLength;
  }

  @override
  E operator [](int index) => value[index];

  @override
  void operator []=(int index, E element) {
    final current = untrackedValue;
    if (current[index] == element) return;
    final next = List<E>.of(current);
    next[index] = element;
    value = next;
  }

  @override
  void add(E element) {
    final next = _copy()..add(element);
    value = next;
  }

  @override
  void addAll(Iterable<E> iterable) {
    if (iterable.isEmpty) return;
    final next = _copy()..addAll(iterable);
    value = next;
  }

  @override
  List<R> cast<R>() => ListSignal<R>(untrackedValue.cast<R>());

  @override
  void clear() {
    if (untrackedValue.isEmpty) return;
    value = <E>[];
  }

  @override
  void fillRange(int start, int end, [E? fill]) {
    if (end <= start) return;
    final next = _copy()..fillRange(start, end, fill);
    if (_listEquals(untrackedValue, next)) return;
    value = next;
  }

  @override
  void insert(int index, E element) {
    final next = _copy()..insert(index, element);
    value = next;
  }

  @override
  void insertAll(int index, Iterable<E> iterable) {
    if (iterable.isEmpty) return;
    final next = _copy()..insertAll(index, iterable);
    value = next;
  }

  @override
  bool remove(Object? element) {
    final current = untrackedValue;
    final index = current.indexWhere((value) => value == element);
    if (index == -1) return false;
    final next = List<E>.of(current)..removeAt(index);
    value = next;
    return true;
  }

  @override
  E removeAt(int index) {
    final current = untrackedValue;
    final removed = current[index];
    final next = List<E>.of(current)..removeAt(index);
    value = next;
    return removed;
  }

  @override
  E removeLast() {
    final current = untrackedValue;
    final removed = current.last;
    final next = List<E>.of(current)..removeLast();
    value = next;
    return removed;
  }

  @override
  void removeRange(int start, int end) {
    if (end <= start) return;
    final next = _copy()..removeRange(start, end);
    value = next;
  }

  @override
  void removeWhere(bool Function(E element) test) {
    final current = untrackedValue;
    final next = List<E>.of(current)..removeWhere(test);
    if (next.length == current.length) return;
    value = next;
  }

  @override
  void replaceRange(int start, int end, Iterable<E> newContents) {
    final next = _copy()..replaceRange(start, end, newContents);
    if (_listEquals(untrackedValue, next)) return;
    value = next;
  }

  @override
  void retainWhere(bool Function(E element) test) {
    final current = untrackedValue;
    final next = List<E>.of(current)..retainWhere(test);
    if (next.length == current.length) return;
    value = next;
  }

  @override
  void setAll(int index, Iterable<E> iterable) {
    final next = _copy()..setAll(index, iterable);
    if (_listEquals(untrackedValue, next)) return;
    value = next;
  }

  @override
  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    final next = _copy()..setRange(start, end, iterable, skipCount);
    if (_listEquals(untrackedValue, next)) return;
    value = next;
  }

  @override
  void shuffle([Random? random]) {
    if (untrackedValue.length < 2) return;
    final next = _copy()..shuffle(random);
    if (_listEquals(untrackedValue, next)) return;
    value = next;
  }

  @override
  void sort([int Function(E a, E b)? compare]) {
    if (untrackedValue.length < 2) return;
    final next = _copy()..sort(compare);
    if (_listEquals(untrackedValue, next)) return;
    value = next;
  }

  @override
  String toString() =>
      'ListSignal<$E>(value: $untrackedValue, '
      'previousValue: $untrackedPreviousValue)';

  List<E> _copy() => List<E>.of(untrackedValue);

  bool _listEquals(List<E> a, List<E> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
