part of '../core.dart';

/// {@template set-signal}
/// `SetSignal` makes easier interacting with sets in a reactive context.
///
/// ```dart
/// final set = SetSignal({1});
///
/// Effect((_) {
///   print(set.first);
/// }); // prints 1
///
/// set[0] = 100; // the effect prints 100
/// ```
/// {@endtemplate}
class SetSignal<E> extends Signal<Set<E>> with SetMixin<E> {
  /// {@macro set-signal}
  factory SetSignal(
    Iterable<E> initialValue, {
    /// {@macro SignalBase.name}
    String? name,

    /// {@macro SignalBase.equals}
    bool? equals,

    /// {@macro SignalBase.autoDispose}
    bool? autoDispose,

    /// {@macro SignalBase.trackInDevTools}
    bool? trackInDevTools,

    /// {@macro SignalBase.comparator}
    ValueComparator<Set<E>?> comparator = identical,

    /// {@macro SignalBase.trackPreviousValue}
    bool? trackPreviousValue,
  }) {
    return SetSignal._internal(
      initialValue: initialValue.toSet(),
      name: name ?? ReactiveContext.main.nameFor('SetSignal'),
      equals: equals ?? SolidartConfig.equals,
      autoDispose: autoDispose ?? SolidartConfig.autoDispose,
      trackInDevTools: trackInDevTools ?? SolidartConfig.devToolsEnabled,
      comparator: comparator,
      trackPreviousValue:
          trackPreviousValue ?? SolidartConfig.trackPreviousValue,
    );
  }

  SetSignal._internal({
    required super.initialValue,
    required super.name,
    required super.equals,
    required super.autoDispose,
    required super.trackInDevTools,
    required super.comparator,
    required super.trackPreviousValue,
  }) : super._internal();

  @override
  void _setValue(Set<E> newValue) {
    if (_compare(_value, newValue)) {
      return;
    }
    _setPreviousValue(Set<E>.of(_value));
    _untrackedValue = _value = newValue;
    _notifyChanged();
  }

  @override
  Set<E> updateValue(Set<E> Function(Set<E> value) callback) =>
      value = callback(Set<E>.of(_value));

  @override
  bool _compare(Set<E>? oldValue, Set<E>? newValue) {
    // skip if the value are equals
    if (equals) {
      return SetEquality<E>().equals(oldValue, newValue);
    }

    // return the [comparator] result
    return comparator(oldValue, newValue);
  }

  /// Adds [value] to the set.
  ///
  /// Returns `true` if [value] (or an equal value) was not yet in the set.
  /// Otherwise returns `false` and the set is not changed.
  ///
  /// Example:
  /// ```dart
  /// final dateTimes = <DateTime>{};
  /// final time1 = DateTime.fromMillisecondsSinceEpoch(0);
  /// final time2 = DateTime.fromMillisecondsSinceEpoch(0);
  /// // time1 and time2 are equal, but not identical.
  /// assert(time1 == time2);
  /// assert(!identical(time1, time2));
  /// final time1Added = dateTimes.add(time1);
  /// print(time1Added); // true
  /// // A value equal to time2 exists already in the set, and the call to
  /// // add doesn't change the set.
  /// final time2Added = dateTimes.add(time2);
  /// print(time2Added); // false
  ///
  /// print(dateTimes); // {1970-01-01 02:00:00.000}
  /// assert(dateTimes.length == 1);
  /// assert(identical(time1, dateTimes.first));
  /// print(dateTimes.length);
  /// ```
  @override
  bool add(E value) {
    _setPreviousValue(Set<E>.of(_value));
    final result = _value.add(value);
    if (result) _notifyChanged();
    return result;
  }

  /// Whether [value] is in the set.
  /// ```dart
  /// final characters = <String>{'A', 'B', 'C'};
  /// final containsB = characters.contains('B'); // true
  /// final containsD = characters.contains('D'); // false
  /// ```
  @override
  bool contains(Object? element) {
    value;
    return _value.contains(element);
  }

  /// An iterator that iterates over the elements of this set.
  ///
  /// The order of iteration is defined by the individual `Set` implementation,
  /// but must be consistent between changes to the set.
  @override
  Iterator<E> get iterator {
    value;
    return _value.iterator;
  }

  /// Returns the number of elements in the iterable.
  ///
  /// This is an efficient operation that doesn't require iterating through
  /// the elements.
  @override
  int get length {
    value;
    return _value.length;
  }

  /// Returns the [index]th element.
  ///
  /// The [index] must be non-negative and less than [length].
  /// Index zero represents the first element (so `iterable.elementAt(0)` is
  /// equivalent to `iterable.first`).
  ///
  /// May iterate through the elements in iteration order, ignoring the
  /// first [index] elements and then returning the next.
  /// Some iterables may have a more efficient way to find the element.
  ///
  /// Example:
  /// ```dart
  /// final numbers = <int>[1, 2, 3, 5, 6, 7];
  /// final elementAt = numbers.elementAt(4); // 6
  /// ```
  @override
  E elementAt(int index) {
    value;
    return _value.elementAt(index);
  }

  /// If an object equal to [object] is in the set, return it.
  ///
  /// Checks whether [object] is in the set, like [contains], and if so,
  /// returns the object in the set, otherwise returns `null`.
  ///
  /// If the equality relation used by the set is not identity,
  /// then the returned object may not be *identical* to [object].
  /// Some set implementations may not be able to implement this method.
  /// If the [contains] method is computed,
  /// rather than being based on an actual object instance,
  /// then there may not be a specific object instance representing the
  /// set element.
  /// ```dart
  /// final characters = <String>{'A', 'B', 'C'};
  /// final containsB = characters.lookup('B');
  /// print(containsB); // B
  /// final containsD = characters.lookup('D');
  /// print(containsD); // null
  /// ```
  @override
  E? lookup(Object? object) {
    value;
    return _value.lookup(object);
  }

  /// Removes [value] from the set.
  ///
  /// Returns `true` if [value] was in the set, and `false` if not.
  /// The method has no effect if [value] was not in the set.
  /// ```dart
  /// final characters = <String>{'A', 'B', 'C'};
  /// final didRemoveB = characters.remove('B'); // true
  /// final didRemoveD = characters.remove('D'); // false
  /// print(characters); // {A, C}
  /// ```
  @override
  bool remove(Object? value) {
    var didRemove = false;
    final index = _value.toList(growable: false).indexOf(value as E);
    if (index >= 0) {
      _setPreviousValue(Set<E>.of(_value));
      _value.remove(value);
      _notifyChanged();
      didRemove = true;
    }

    return didRemove;
  }

  /// Removes each element of [elements] from this set.
  /// ```dart
  /// final characters = <String>{'A', 'B', 'C'};
  /// characters.removeAll({'A', 'B', 'X'});
  /// print(characters); // {C}
  /// ```
  @override
  void removeAll(Iterable<Object?> elements) {
    _setPreviousValue(Set<E>.of(_value));
    var hasChanges = false;
    for (final element in elements) {
      final removed = _value.remove(element);
      if (!hasChanges && removed) {
        hasChanges = true;
      }
    }

    if (hasChanges) _notifyChanged();
  }

  /// Removes all elements of this set that satisfy [test].
  /// ```dart
  /// final characters = <String>{'A', 'B', 'C'};
  /// characters.removeWhere((element) => element.startsWith('B'));
  /// print(characters); // {A, C}
  /// ```
  @override
  void removeWhere(bool Function(E element) test) {
    final toRemove = <E>[];
    for (final element in this) {
      if (test(element)) {
        toRemove.add(element);
      }
    }
    removeAll(toRemove);
  }

  /// Creates a [Set] with the same elements and behavior as this `Set`.
  ///
  /// The returned set behaves the same as this set
  /// with regard to adding and removing elements.
  /// It initially contains the same elements.
  /// If this set specifies an ordering of the elements,
  /// the returned set will have the same order.
  @override
  Set<E> toSet() {
    value;
    return _value.toSet();
  }

  /// Provides a view of this set as a set of [R] instances.
  ///
  /// If this set contains only instances of [R], all read operations
  /// will work correctly. If any operation tries to access an element
  /// that is not an instance of [R], the access will throw instead.
  ///
  /// Elements added to the set (e.g., by using [add] or [addAll])
  /// must be instances of [R] to be valid arguments to the adding function,
  /// and they must be instances of [E] as well to be accepted by
  /// this set as well.
  ///
  /// Methods which accept one or more `Object?` as argument,
  /// like [contains], [remove] and [removeAll],
  /// will pass the argument directly to the this set's method
  /// without any checks.
  /// That means that you can do `setOfStrings.cast<int>().remove("a")`
  /// successfully, even if it looks like it shouldn't have any effect.
  @override
  Set<R> cast<R>() => SetSignal(_value.cast<R>());

  /// Removes all elements from the set.
  /// ```dart
  /// final characters = <String>{'A', 'B', 'C'};
  /// characters.clear(); // {}
  /// ```
  @override
  void clear() {
    if (_value.isNotEmpty) {
      _setPreviousValue(Set<E>.of(_value));
      _value.clear();
      _notifyChanged();
    }
  }

  /// Removes all elements of this set that are not elements in [elements].
  ///
  /// Checks for each element of [elements] whether there is an element in this
  /// set that is equal to it (according to `this.contains`), and if so, the
  /// equal element in this set is retained, and elements that are not equal
  /// to any element in [elements] are removed.
  /// ```dart
  /// final characters = <String>{'A', 'B', 'C'};
  /// characters.retainAll({'A', 'B', 'X'});
  /// print(characters); // {A, B}
  /// ```
  @override
  void retainAll(Iterable<Object?> elements) {
    // Create a copy of the set, remove all of elements from the copy,
    // then remove all remaining elements in copy from this.
    final toRemove = _value.toSet();
    for (final e in elements) {
      toRemove.remove(e);
    }
    removeAll(toRemove);
  }

  /// Removes all elements of this set that fail to satisfy [test].
  /// ```dart
  /// final characters = <String>{'A', 'B', 'C'};
  /// characters.retainWhere(
  ///     (element) => element.startsWith('B') || element.startsWith('C'));
  /// print(characters); // {B, C}
  /// ```
  @override
  void retainWhere(bool Function(E element) test) {
    final removed = <E>[];
    for (var i = _value.length - 1; i >= 0; --i) {
      final element = _value.elementAt(i);
      if (!test(element)) {
        removed.add(element);
      }
    }
    if (removed.isNotEmpty) {
      _setPreviousValue(Set<E>.of(_value));
      for (final item in removed) {
        _value.remove(item);
      }
    }
  }

  /// Creates a [List] containing the elements of this [Iterable].
  ///
  /// The elements are in iteration order.
  /// The list is fixed-length if [growable] is false.
  ///
  /// Example:
  /// ```dart
  /// final planets = <int, String>{1: 'Mercury', 2: 'Venus', 3: 'Mars'};
  /// final keysList = planets.keys.toList(growable: false); // [1, 2, 3]
  /// final valuesList =
  ///     planets.values.toList(growable: false); // [Mercury, Venus, Mars]
  /// ```
  @override
  List<E> toList({bool growable = true}) {
    value;
    return _value.toList(growable: growable);
  }

  /// The last element that satisfies the given predicate [test].
  ///
  /// An iterable that can access its elements directly may check its
  /// elements in any order (for example a list starts by checking the
  /// last element and then moves towards the start of the list).
  /// The default implementation iterates elements in iteration order,
  /// checks `test(element)` for each,
  /// and finally returns that last one that matched.
  ///
  /// Example:
  /// ```dart
  /// final numbers = <int>[1, 2, 3, 5, 6, 7];
  /// var result = numbers.lastWhere((element) => element < 5); // 3
  /// result = numbers.lastWhere((element) => element > 5); // 7
  /// result = numbers.lastWhere((element) => element > 10,
  ///     orElse: () => -1); // -1
  /// ```
  ///
  /// If no element satisfies [test], the result of invoking the [orElse]
  /// function is returned.
  /// If [orElse] is omitted, it defaults to throwing a [StateError].
  @override
  E lastWhere(bool Function(E value) test, {E Function()? orElse}) {
    value;
    return _value.lastWhere(test, orElse: orElse);
  }

  /// The first element that satisfies the given predicate [test].
  ///
  /// Iterates through elements and returns the first to satisfy [test].
  ///
  /// Example:
  /// ```dart
  /// final numbers = <int>[1, 2, 3, 5, 6, 7];
  /// var result = numbers.firstWhere((element) => element < 5); // 1
  /// result = numbers.firstWhere((element) => element > 5); // 6
  /// result =
  ///     numbers.firstWhere((element) => element > 10, orElse: () => -1); // -1
  /// ```
  ///
  /// If no element satisfies [test], the result of invoking the [orElse]
  /// function is returned.
  /// If [orElse] is omitted, it defaults to throwing a [StateError].
  /// Stops iterating on the first matching element.
  @override
  E firstWhere(bool Function(E value) test, {E Function()? orElse}) {
    value;
    return _value.firstWhere(test, orElse: orElse);
  }

  /// Checks that this iterable has only one element, and returns that element.
  ///
  /// Throws a [StateError] if `this` is empty or has more than one element.
  /// This operation will not iterate past the second element.
  @override
  E get single {
    value;
    return _value.single;
  }

  /// The single element that satisfies [test].
  ///
  /// Checks elements to see if `test(element)` returns true.
  /// If exactly one element satisfies [test], that element is returned.
  /// If more than one matching element is found, throws [StateError].
  /// If no matching element is found, returns the result of [orElse].
  /// If [orElse] is omitted, it defaults to throwing a [StateError].
  ///
  /// Example:
  /// ```dart
  /// final numbers = <int>[2, 2, 10];
  /// var result = numbers.singleWhere((element) => element > 5); // 10
  /// ```
  /// When no matching element is found, the result of calling [orElse] is
  /// returned instead.
  /// ```dart continued
  /// result = numbers.singleWhere((element) => element == 1,
  ///     orElse: () => -1); // -1
  /// ```
  /// There must not be more than one matching element.
  /// ```dart continued
  /// result = numbers.singleWhere((element) => element == 2); // Throws Error.
  /// ```
  @override
  E singleWhere(bool Function(E value) test, {E Function()? orElse}) {
    value;
    return _value.singleWhere(test, orElse: orElse);
  }

  /// The first element.
  ///
  /// Throws a [StateError] if `this` is empty.
  /// Otherwise returns the first element in the iteration order,
  /// equivalent to `this.elementAt(0)`.
  @override
  E get first {
    value;
    return _value.first;
  }

  /// The last element.
  ///
  /// Throws a [StateError] if `this` is empty.
  /// Otherwise may iterate through the elements and returns the last one
  /// seen.
  /// Some iterables may have more efficient ways to find the last element
  /// (for example a list can directly access the last element,
  /// without iterating through the previous ones).
  @override
  E get last {
    value;
    return _value.last;
  }

  @override
  String toString() =>
      '''SetSignal<$E>(value: $_value, previousValue: $_previousValue)''';

  void _notifyChanged() {
    _reportChanged();
    _notifyListeners();
    _notifySignalUpdate();
  }
}
