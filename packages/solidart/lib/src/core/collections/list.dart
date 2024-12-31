part of '../core.dart';

/// {@template list-signal}
/// `ListSignal` makes easier interacting with lists in a reactive context.
///
/// ```dart
/// final list = ListSignal([1]);
///
/// Effect((_) {
///   print(list.first);
/// }); // prints 1
///
/// list[0] = 100; // the effect prints 100
/// ```
/// {@endtemplate}
class ListSignal<E> extends Signal<List<E>> with ListMixin<E> {
  /// {@macro list-signal}
  factory ListSignal(
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
    ValueComparator<List<E>?> comparator = identical,
  }) {
    return ListSignal._internal(
      initialValue: initialValue.toList(),
      name: name ?? ReactiveContext.main.nameFor('ListSignal'),
      equals: equals ?? SolidartConfig.equals,
      autoDispose: autoDispose ?? SolidartConfig.autoDispose,
      trackInDevTools: trackInDevTools ?? SolidartConfig.devToolsEnabled,
      comparator: comparator,
    );
  }

  ListSignal._internal({
    required super.initialValue,
    required super.name,
    required super.equals,
    required super.autoDispose,
    required super.trackInDevTools,
    required super.comparator,
  }) : super._internal();

  @override
  void _setValue(List<E> newValue) {
    if (_compare(_value, newValue)) {
      return;
    }
    _setPreviousValue(List<E>.of(_value));
    _value = newValue;
    _notifyChanged();
  }

  @override
  List<E> updateValue(List<E> Function(List<E> value) callback) =>
      value = callback(List<E>.of(_value));

  @override
  bool _compare(List<E>? oldValue, List<E>? newValue) {
    // skip if the value are equals
    if (equals) {
      return ListEquality<E>().equals(oldValue, newValue);
    }

    // return the [comparator] result
    return comparator(oldValue, newValue);
  }

  /// The number of objects in this list.
  ///
  /// The valid indices for a list are `0` through `length - 1`.
  /// ```dart
  /// final numbers = <int>[1, 2, 3];
  /// print(numbers.length); // 3
  /// ```
  @override
  int get length {
    _reportObserved();
    return _value.length;
  }

  /// Setting the `length` changes the number of elements in the list.
  ///
  /// The list must be growable.
  /// If [newLength] is greater than current length,
  /// new entries are initialized to `null`,
  /// so [newLength] must not be greater than the current length
  /// if the element type [E] is non-nullable.
  ///
  /// ```dart
  /// final maybeNumbers = <int?>[1, null, 3];
  /// maybeNumbers.length = 5;
  /// print(maybeNumbers); // [1, null, 3, null, null]
  /// maybeNumbers.length = 2;
  /// print(maybeNumbers); // [1, null]
  ///
  /// final numbers = <int>[1, 2, 3];
  /// numbers.length = 1;
  /// print(numbers); // [1]
  /// numbers.length = 5; // Throws, cannot add `null`s.
  /// ```
  @override
  set length(int newLength) {
    if (newLength == _value.length) return;
    _value.length = newLength;
    _notifyChanged();
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
    _reportObserved();
    return _value.elementAt(index);
  }

  /// Returns the concatenation of this list and [other].
  ///
  /// Returns a new list containing the elements of this list followed by
  /// the elements of [other].
  ///
  /// The default behavior is to return a normal growable list.
  /// Some list types may choose to return a list of the same type as themselves
  /// (see Uint8List.+);
  @override
  List<E> operator +(List<E> other) {
    _reportObserved();
    return _value + other;
  }

  /// The object at the given [index] in the list.
  ///
  /// The [index] must be a valid index of this list,
  /// which means that `index` must be non-negative and
  /// less than [length].
  @override
  E operator [](int index) {
    _reportObserved();
    return _value[index];
  }

  /// Sets the value at the given [index] in the list to [value].
  ///
  /// The [index] must be a valid index of this list,
  /// which means that `index` must be non-negative and
  /// less than [length].
  @override
  void operator []=(int index, E value) {
    final oldValue = _value[index];

    if (oldValue != value) {
      _setPreviousValue(List<E>.of(_value));
      _value[index] = value;
      _notifyChanged();
    }
  }

  /// Adds [value] to the end of this list,
  /// extending the length by one.
  ///
  /// The list must be growable.
  ///
  /// ```dart
  /// final numbers = <int>[1, 2, 3];
  /// numbers.add(4);
  /// print(numbers); // [1, 2, 3, 4]
  /// ```
  @override
  void add(E element) {
    _setPreviousValue(List<E>.of(_value));
    _value.add(element);
    _notifyChanged();
  }

  /// Appends all objects of [iterable] to the end of this list.
  ///
  /// Extends the length of the list by the number of objects in [iterable].
  /// The list must be growable.
  ///
  /// ```dart
  /// final numbers = <int>[1, 2, 3];
  /// numbers.addAll([4, 5, 6]);
  /// print(numbers); // [1, 2, 3, 4, 5, 6]
  /// ```
  @override
  void addAll(Iterable<E> iterable) {
    if (iterable.isNotEmpty) {
      _setPreviousValue(List<E>.of(_value));
      _value.addAll(iterable);
      _notifyChanged();
    }
  }

  /// A new `Iterator` that allows iterating the elements of this `Iterable`.
  ///
  /// Iterable classes may specify the iteration order of their elements
  /// (for example [List] always iterate in index order),
  /// or they may leave it unspecified (for example a hash-based [Set]
  /// may iterate in any order).
  ///
  /// Each time `iterator` is read, it returns a new iterator,
  /// which can be used to iterate through all the elements again.
  /// The iterators of the same iterable can be stepped through independently,
  /// but should return the same elements in the same order,
  /// as long as the underlying collection isn't changed.
  ///
  /// Modifying the collection may cause new iterators to produce
  /// different elements, and may change the order of existing elements.
  /// A [List] specifies its iteration order precisely,
  /// so modifying the list changes the iteration order predictably.
  /// A hash-based [Set] may change its iteration order completely
  /// when adding a new element to the set.
  ///
  /// Modifying the underlying collection after creating the new iterator
  /// may cause an error the next time [Iterator.moveNext] is called
  /// on that iterator.
  /// Any *modifiable* iterable class should specify which operations will
  /// break iteration.
  @override
  Iterator<E> get iterator {
    _reportObserved();
    return _value.iterator;
  }

  /// The last index in the list that satisfies the provided [test].
  ///
  /// Searches the list from index [start] to 0.
  /// The first time an object `o` is encountered so that `test(o)` is true,
  /// the index of `o` is returned.
  /// If [start] is omitted, it defaults to the [length] of the list.
  ///
  /// ```dart
  /// final notes = <String>['do', 're', 'mi', 're'];
  /// final first = notes.lastIndexWhere((note) => note.startsWith('r')); // 3
  /// final second = notes.lastIndexWhere((note) => note.startsWith('r'),
  ///     2); // 1
  /// ```
  ///
  /// Returns -1 if element is not found.
  /// ```dart
  /// final notes = <String>['do', 're', 'mi', 're'];
  /// final index = notes.lastIndexWhere((note) => note.startsWith('k'));
  /// print(index); // -1
  /// ```
  @override
  int lastIndexWhere(bool Function(E element) test, [int? start]) {
    _reportObserved();
    return _value.lastIndexWhere(test, start);
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
  E lastWhere(bool Function(E element) test, {E Function()? orElse}) {
    _reportObserved();
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
  E firstWhere(bool Function(E element) test, {E Function()? orElse}) {
    _reportObserved();
    return _value.firstWhere(test, orElse: orElse);
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
  E singleWhere(bool Function(E element) test, {E Function()? orElse}) {
    _reportObserved();
    return _value.singleWhere(test, orElse: orElse);
  }

  /// Checks that this iterable has only one element, and returns that element.
  ///
  /// Throws a [StateError] if `this` is empty or has more than one element.
  /// This operation will not iterate past the second element.
  @override
  E get single {
    _reportObserved();
    return _value.single;
  }

  /// The first element.
  ///
  /// Throws a [StateError] if `this` is empty.
  /// Otherwise returns the first element in the iteration order,
  /// equivalent to `this.elementAt(0)`.
  @override
  E get first {
    _reportObserved();
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
    _reportObserved();
    return _value.last;
  }

  /// Returns a new list containing the elements between [start] and [end].
  ///
  /// The new list is a `List<E>` containing the elements of this list at
  /// positions greater than or equal to [start] and less than [end] in the same
  /// order as they occur in this list.
  ///
  /// ```dart
  /// final colors = <String>['red', 'green', 'blue', 'orange', 'pink'];
  /// print(colors.sublist(1, 3)); // [green, blue]
  /// ```
  ///
  /// If [end] is omitted, it defaults to the [length] of this list.
  ///
  /// ```dart
  /// final colors = <String>['red', 'green', 'blue', 'orange', 'pink'];
  /// print(colors.sublist(3)); // [orange, pink]
  /// ```
  ///
  /// The `start` and `end` positions must satisfy the relations
  /// 0 ≤ `start` ≤ `end` ≤ [length].
  /// If `end` is equal to `start`, then the returned list is empty.
  @override
  List<E> sublist(int start, [int? end]) {
    _reportObserved();
    return _value.sublist(start, end);
  }

  /// Returns a view of this list as a list of [R] instances.
  ///
  /// If this list contains only instances of [R], all read operations
  /// will work correctly. If any operation tries to read an element
  /// that is not an instance of [R], the access will throw instead.
  ///
  /// Elements added to the list (e.g., by using [add] or [addAll])
  /// must be instances of [R] to be valid arguments to the adding function,
  /// and they must also be instances of [E] to be accepted by
  /// this list as well.
  ///
  /// Methods which accept `Object?` as argument, like [contains] and [remove],
  /// will pass the argument directly to the this list's method
  /// without any checks.
  /// That means that you can do `listOfStrings.cast<int>().remove("a")`
  /// successfully, even if it looks like it shouldn't have any effect.
  ///
  /// Typically implemented as `List.castFrom<E, R>(this)`.
  @override
  List<R> cast<R>() => ListSignal(_value.cast<R>());

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
    _reportObserved();
    return _value.toList(growable: growable);
  }

  /// The first element of the list.
  ///
  /// The list must be non-empty when accessing its first element.
  ///
  /// The first element of a list can be modified, unlike an [Iterable].
  /// A `list.first` is equivalent to `list[0]`,
  /// both for getting and setting the value.
  ///
  /// ```dart
  /// final numbers = <int>[1, 2, 3];
  /// print(numbers.first); // 1
  /// numbers.first = 10;
  /// print(numbers.first); // 10
  /// numbers.clear();
  /// numbers.first; // Throws.
  /// ```
  @override
  set first(E value) {
    final oldValue = _value.first;
    if (oldValue != value) {
      _setPreviousValue(List<E>.of(_value));
      _value.first = value;
      _notifyChanged();
    }
  }

  /// The last element of the list.
  ///
  /// The list must be non-empty when accessing its last element.
  ///
  /// The last element of a list can be modified, unlike an [Iterable].
  /// A `list.last` is equivalent to `theList[theList.length - 1]`,
  /// both for getting and setting the value.
  ///
  /// ```dart
  /// final numbers = <int>[1, 2, 3];
  /// print(numbers.last); // 3
  /// numbers.last = 10;
  /// print(numbers.last); // 10
  /// numbers.clear();
  /// numbers.last; // Throws.
  /// ```
  @override
  set last(E value) {
    final oldValue = _value.last;
    if (oldValue != value) {
      _setPreviousValue(List<E>.of(_value));
      _value.last = value;
      _notifyChanged();
    }
  }

  /// Removes all objects from this list; the length of the list becomes zero.
  ///
  /// The list must be growable.
  ///
  /// ```dart
  /// final numbers = <int>[1, 2, 3];
  /// numbers.clear();
  /// print(numbers.length); // 0
  /// print(numbers); // []
  /// ```
  @override
  void clear() {
    if (_value.isNotEmpty) {
      _setPreviousValue(List<E>.of(_value));
      _value.clear();
      _notifyChanged();
    }
  }

  /// Overwrites a range of elements with [fillValue].
  ///
  /// Sets the positions greater than or equal to [start] and less than [end],
  /// to [fillValue].
  ///
  /// The provided range, given by [start] and [end], must be valid.
  /// A range from [start] to [end] is valid if 0 ≤ `start` ≤ `end` ≤ [length].
  /// An empty range (with `end == start`) is valid.
  ///
  /// If the element type is not nullable, the [fillValue] must be provided and
  /// must be non-`null`.
  ///
  /// Example:
  /// ```dart
  /// final words = List.filled(5, 'old');
  /// print(words); // [old, old, old, old, old]
  /// words.fillRange(1, 3, 'new');
  /// print(words); // [old, new, new, old, old]
  /// ```
  @override
  void fillRange(int start, int end, [E? fillValue]) {
    if (end > start) {
      _setPreviousValue(List<E>.of(_value));
      _value.fillRange(start, end, fillValue);
      _notifyChanged();
    }
  }

  /// Inserts [element] at position [index] in this list.
  ///
  /// This increases the length of the list by one and shifts all objects
  /// at or after the index towards the end of the list.
  ///
  /// The list must be growable.
  /// The [index] value must be non-negative and no greater than [length].
  ///
  /// ```dart
  /// final numbers = <int>[1, 2, 3, 4];
  /// const index = 2;
  /// numbers.insert(index, 10);
  /// print(numbers); // [1, 2, 10, 3, 4]
  /// ```
  @override
  void insert(int index, E element) {
    _setPreviousValue(List<E>.of(_value));
    _value.insert(index, element);
    _notifyChanged();
  }

  /// Inserts all objects of [iterable] at position [index] in this list.
  ///
  /// This increases the length of the list by the length of [iterable] and
  /// shifts all later objects towards the end of the list.
  ///
  /// The list must be growable.
  /// The [index] value must be non-negative and no greater than [length].
  /// ```dart
  /// final numbers = <int>[1, 2, 3, 4];
  /// final insertItems = [10, 11];
  /// numbers.insertAll(2, insertItems);
  /// print(numbers); // [1, 2, 10, 11, 3, 4]
  /// ```
  @override
  void insertAll(int index, Iterable<E> iterable) {
    if (iterable.isNotEmpty) {
      _setPreviousValue(List<E>.of(_value));
      _value.insertAll(index, iterable);
      _notifyChanged();
    }
  }

  /// Removes the first occurrence of [value] from this list.
  ///
  /// Returns true if [value] was in the list, false otherwise.
  /// The list must be growable.
  ///
  /// ```dart
  /// final parts = <String>['head', 'shoulders', 'knees', 'toes'];
  /// final retVal = parts.remove('head'); // true
  /// print(parts); // [shoulders, knees, toes]
  /// ```
  /// The method has no effect if [value] was not in the list.
  /// ```dart
  /// final parts = <String>['shoulders', 'knees', 'toes'];
  /// // Note: 'head' has already been removed.
  /// final retVal = parts.remove('head'); // false
  /// print(parts); // [shoulders, knees, toes]
  /// ```
  @override
  bool remove(Object? element) {
    var didRemove = false;
    final index = _value.indexOf(element as E);
    if (index >= 0) {
      _setPreviousValue(List<E>.of(_value));
      _value.removeAt(index);
      _notifyChanged();
      didRemove = true;
    }

    return didRemove;
  }

  /// Removes the object at position [index] from this list.
  ///
  /// This method reduces the length of `this` by one and moves all later
  /// objects down by one position.
  ///
  /// Returns the removed value.
  ///
  /// The [index] must be in the range `0 ≤ index < length`.
  /// The list must be growable.
  /// ```dart
  /// final parts = <String>['head', 'shoulder', 'knees', 'toes'];
  /// final retVal = parts.removeAt(2); // knees
  /// print(parts); // [head, shoulder, toes]
  /// ```
  @override
  E removeAt(int index) {
    _setPreviousValue(List<E>.of(_value));

    final removed = _value.removeAt(index);
    _notifyChanged();

    return removed;
  }

  /// Removes and returns the last object in this list.
  ///
  /// The list must be growable and non-empty.
  /// ```dart
  /// final parts = <String>['head', 'shoulder', 'knees', 'toes'];
  /// final retVal = parts.removeLast(); // toes
  /// print(parts); // [head, shoulder, knees]
  /// ```
  @override
  E removeLast() {
    _setPreviousValue(List<E>.of(_value));

    final removed = _value.removeLast();
    _notifyChanged();

    return removed;
  }

  /// Removes a range of elements from the list.
  ///
  /// Removes the elements with positions greater than or equal to [start]
  /// and less than [end], from the list.
  /// This reduces the list's length by `end - start`.
  ///
  /// The provided range, given by [start] and [end], must be valid.
  /// A range from [start] to [end] is valid if 0 ≤ `start` ≤ `end` ≤ [length].
  /// An empty range (with `end == start`) is valid.
  ///
  /// The list must be growable.
  /// ```dart
  /// final numbers = <int>[1, 2, 3, 4, 5];
  /// numbers.removeRange(1, 4);
  /// print(numbers); // [1, 5]
  /// ```
  @override
  void removeRange(int start, int end) {
    if (end > start) {
      _setPreviousValue(List<E>.of(_value));
      _value.removeRange(start, end);
      _notifyChanged();
    }
  }

  /// Removes all objects from this list that satisfy [test].
  ///
  /// An object `o` satisfies [test] if `test(o)` is true.
  /// ```dart
  /// final numbers = <String>['one', 'two', 'three', 'four'];
  /// numbers.removeWhere((item) => item.length == 3);
  /// print(numbers); // [three, four]
  /// ```
  /// The list must be growable.
  @override
  void removeWhere(bool Function(E element) test) {
    final removedIndexes = <int>[];
    for (var i = _value.length - 1; i >= 0; --i) {
      final element = _value[i];
      if (test(element)) {
        removedIndexes.add(i);
      }
    }
    if (removedIndexes.isNotEmpty) {
      _setPreviousValue(List<E>.of(_value));
      for (final index in removedIndexes) {
        _value.removeAt(index);
      }
      _notifyChanged();
    }
  }

  /// Replaces a range of elements with the elements of [replacements].
  ///
  /// Removes the objects in the range from [start] to [end],
  /// then inserts the elements of [replacements] at [start].
  /// ```dart
  /// final numbers = <int>[1, 2, 3, 4, 5];
  /// final replacements = [6, 7];
  /// numbers.replaceRange(1, 4, replacements);
  /// print(numbers); // [1, 6, 7, 5]
  /// ```
  /// The provided range, given by [start] and [end], must be valid.
  /// A range from [start] to [end] is valid if 0 ≤ `start` ≤ `end` ≤ [length].
  /// An empty range (with `end == start`) is valid.
  ///
  /// The operation `list.replaceRange(start, end, replacements)`
  /// is roughly equivalent to:
  /// ```dart
  /// final numbers = <int>[1, 2, 3, 4, 5];
  /// numbers.removeRange(1, 4);
  /// final replacements = [6, 7];
  /// numbers.insertAll(1, replacements);
  /// print(numbers); // [1, 6, 7, 5]
  /// ```
  /// but may be more efficient.
  ///
  /// The list must be growable.
  /// This method does not work on fixed-length lists, even when [replacements]
  /// has the same number of elements as the replaced range. In that case use
  /// [setRange] instead.
  @override
  void replaceRange(int start, int end, Iterable<E> replacements) {
    if (end > start || replacements.isNotEmpty) {
      _setPreviousValue(List<E>.of(_value));
      _value.replaceRange(start, end, replacements);
      _notifyChanged();
    }
  }

  /// Removes all objects from this list that fail to satisfy [test].
  ///
  /// An object `o` satisfies [test] if `test(o)` is true.
  /// ```dart
  /// final numbers = <String>['one', 'two', 'three', 'four'];
  /// numbers.retainWhere((item) => item.length == 3);
  /// print(numbers); // [one, two]
  /// ```
  /// The list must be growable.
  @override
  void retainWhere(bool Function(E element) test) {
    final removedIndexes = <int>[];
    for (var i = _value.length - 1; i >= 0; --i) {
      final element = _value[i];
      if (!test(element)) {
        removedIndexes.add(i);
      }
    }
    if (removedIndexes.isNotEmpty) {
      _setPreviousValue(List<E>.of(_value));
      for (final index in removedIndexes) {
        _value.removeAt(index);
      }
    }
  }

  /// Overwrites elements with the objects of [iterable].
  ///
  /// The elements of [iterable] are written into this list,
  /// starting at position [index].
  /// This operation does not increase the length of the list.
  ///
  /// The [index] must be non-negative and no greater than [length].
  ///
  /// The [iterable] must not have more elements than what can fit from [index]
  /// to [length].
  ///
  /// If `iterable` is based on this list, its values may change _during_ the
  /// `setAll` operation.
  /// ```dart
  /// final list = <String>['a', 'b', 'c', 'd'];
  /// list.setAll(1, ['bee', 'sea']);
  /// print(list); // [a, bee, sea, d]
  /// ```
  @override
  void setAll(int index, Iterable<E> iterable) {
    if (iterable.isNotEmpty) {
      _setPreviousValue(List<E>.of(_value));

      _value.setAll(index, iterable);
      _notifyChanged();
    }
  }

  /// Writes some elements of [iterable] into a range of this list.
  ///
  /// Copies the objects of [iterable], skipping [skipCount] objects first,
  /// into the range from [start], inclusive, to [end], exclusive, of this list.
  /// ```dart
  /// final list1 = <int>[1, 2, 3, 4];
  /// final list2 = <int>[5, 6, 7, 8, 9];
  /// // Copies the 4th and 5th items in list2 as the 2nd and 3rd items
  /// // of list1.
  /// const skipCount = 3;
  /// list1.setRange(1, 3, list2, skipCount);
  /// print(list1); // [1, 8, 9, 4]
  /// ```
  /// The provided range, given by [start] and [end], must be valid.
  /// A range from [start] to [end] is valid if 0 ≤ `start` ≤ `end` ≤ [length].
  /// An empty range (with `end == start`) is valid.
  ///
  /// The [iterable] must have enough objects to fill the range from `start`
  /// to `end` after skipping [skipCount] objects.
  ///
  /// If `iterable` is this list, the operation correctly copies the elements
  /// originally in the range from `skipCount` to `skipCount + (end - start)` to
  /// the range `start` to `end`, even if the two ranges overlap.
  ///
  /// If `iterable` depends on this list in some other way, no guarantees are
  /// made.
  @override
  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    if (end > start) {
      _setPreviousValue(List<E>.of(_value));
      _value.setRange(start, end, iterable, skipCount);
      _notifyChanged();
    }
  }

  /// Shuffles the elements of this list randomly.
  /// ```dart
  /// final numbers = <int>[1, 2, 3, 4, 5];
  /// numbers.shuffle();
  /// print(numbers); // [1, 3, 4, 5, 2] OR some other random result.
  /// ```
  @override
  void shuffle([Random? random]) {
    if (_value.isNotEmpty) {
      final oldList = _value.toList(growable: false);
      final newList = _value.toList()..shuffle(random);
      var hasChanges = false;
      for (var i = 0; i < newList.length; ++i) {
        final oldValue = oldList[i];
        final newValue = newList[i];
        if (newValue != oldValue) {
          hasChanges = true;
          break;
        }
      }
      if (hasChanges) {
        _setPreviousValue(List<E>.of(_value));
        _value = newList;
        _notifyChanged();
      }
    }
  }

  /// Sorts this list according to the order specified by the [compare] function
  ///
  /// The [compare] function must act as a [Comparator].
  /// ```dart
  /// final numbers = <String>['two', 'three', 'four'];
  /// // Sort from shortest to longest.
  /// numbers.sort((a, b) => a.length.compareTo(b.length));
  /// print(numbers); // [two, four, three]
  /// ```
  /// The default [List] implementations use [Comparable.compare] if
  /// [compare] is omitted.
  /// ```dart
  /// final numbers = <int>[13, 2, -11, 0];
  /// numbers.sort();
  /// print(numbers); // [-11, 0, 2, 13]
  /// ```
  /// In that case, the elements of the list must be [Comparable] to
  /// each other.
  ///
  /// A [Comparator] may compare objects as equal (return zero), even if they
  /// are distinct objects.
  /// The sort function is not guaranteed to be stable, so distinct objects
  /// that compare as equal may occur in any order in the result:
  /// ```dart
  /// final numbers = <String>['one', 'two', 'three', 'four'];
  /// numbers.sort((a, b) => a.length.compareTo(b.length));
  /// print(numbers); // [one, two, four, three] OR [two, one, four, three]
  /// ```
  @override
  void sort([int Function(E a, E b)? compare]) {
    if (_value.isNotEmpty) {
      final oldList = _value.toList(growable: false);
      final newList = _value.toList()..sort(compare);
      var hasChanges = false;
      for (var i = 0; i < newList.length; ++i) {
        final oldValue = oldList[i];
        final newValue = newList[i];
        if (newValue != oldValue) {
          hasChanges = true;
          break;
        }
      }
      if (hasChanges) {
        _setPreviousValue(List<E>.of(_value));
        _value = newList;
        _notifyChanged();
      }
    }
  }

  @override
  String toString() =>
      '''ListSignal<$E>(value: $_value, previousValue: $_previousValue)''';

  void _notifyChanged() {
    // _reportChanged();
    _notifyListeners();
    _notifySignalUpdate();
  }
}
