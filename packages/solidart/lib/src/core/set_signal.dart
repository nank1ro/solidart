part of '../solidart.dart';

/// {@template solidart.set-signal}
/// A reactive wrapper around a [Set] that copies on write.
///
/// Mutations create a new set instance so that updates are observable:
/// ```dart
/// final set = SetSignal({1});
/// Effect(() => print(set.length));
/// set.add(2); // triggers effect
/// ```
///
/// Reads (like `length` or `contains`) establish dependencies.
/// {@endtemplate}
class SetSignal<E> extends Signal<Set<E>> with SetMixin<E> {
  /// {@macro solidart.set-signal}
  ///
  /// Creates a reactive set with the provided initial values.
  SetSignal(
    Iterable<E> initialValue, {
    bool? autoDispose,
    String? name,
    ValueComparator<Set<E>> equals = identical,
    bool? trackPreviousValue,
    bool? trackInDevTools,
  }) : super(
         Set<E>.of(initialValue),
         autoDispose: autoDispose,
         name: name,
         equals: equals,
         trackPreviousValue: trackPreviousValue,
         trackInDevTools: trackInDevTools,
       );

  @override
  Iterator<E> get iterator => value.iterator;

  @override
  int get length => value.length;

  @override
  bool add(E value) {
    final current = untrackedValue;
    if (current.contains(value)) return false;
    final next = Set<E>.of(current)..add(value);
    this.value = next;
    return true;
  }

  @override
  void addAll(Iterable<E> elements) {
    if (elements.isEmpty) return;
    final next = _copy()..addAll(elements);
    if (next.length == untrackedValue.length) return;
    value = next;
  }

  @override
  Set<R> cast<R>() => SetSignal<R>(untrackedValue.cast<R>());

  @override
  void clear() {
    if (untrackedValue.isEmpty) return;
    value = <E>{};
  }

  @override
  bool contains(Object? element) {
    value;
    return untrackedValue.contains(element);
  }

  @override
  E? lookup(Object? element) {
    value;
    return untrackedValue.lookup(element);
  }

  @override
  bool remove(Object? value) {
    final current = untrackedValue;
    if (!current.contains(value)) return false;
    final next = Set<E>.of(current)..remove(value);
    this.value = next;
    return true;
  }

  @override
  void removeAll(Iterable<Object?> elements) {
    if (elements.isEmpty) return;
    final current = untrackedValue;
    final next = Set<E>.of(current)..removeAll(elements);
    if (next.length == current.length) return;
    value = next;
  }

  @override
  void removeWhere(bool Function(E element) test) {
    final current = untrackedValue;
    final next = Set<E>.of(current)..removeWhere(test);
    if (next.length == current.length) return;
    value = next;
  }

  @override
  void retainAll(Iterable<Object?> elements) {
    final current = untrackedValue;
    final next = Set<E>.of(current)..retainAll(elements);
    if (next.length == current.length) return;
    value = next;
  }

  @override
  void retainWhere(bool Function(E element) test) {
    final current = untrackedValue;
    final next = Set<E>.of(current)..retainWhere(test);
    if (next.length == current.length) return;
    value = next;
  }

  @override
  Set<E> toSet() => Set<E>.of(untrackedValue);

  @override
  String toString() =>
      'SetSignal<$E>(value: $untrackedValue, '
      'previousValue: $untrackedPreviousValue)';

  Set<E> _copy() => Set<E>.of(untrackedValue);
}
