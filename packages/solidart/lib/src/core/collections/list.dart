part of '../core.dart';

enum _ListBacking { plain, typed, unmodifiable, opaque }

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
class ListSignal<E> extends Signal<List<E>>
    with ListMixin<E>, _CollectionSignal<List<E>> {
  /// {@macro list-signal}
  ListSignal(
    Iterable<E> initialValue, {

    /// {@macro SignalBase.name}
    super.name,

    /// {@macro SignalBase.equals}
    super.equals,

    /// {@macro SignalBase.autoDispose}
    super.autoDispose,

    /// {@macro SignalBase.trackInDevTools}
    super.trackInDevTools,

    /// {@macro SignalBase.comparator}
    super.comparator = identical,

    /// {@macro SignalBase.trackPreviousValue}
    super.trackPreviousValue,
  }) : super(initialValue.toList());

  @override
  List<E> updateValue(List<E> Function(List<E> value) callback) {
    return setValue(callback(List<E>.of(_untrackedValue)));
  }

  @override
  void _setValueAndNotify(List<E> newValue) {
    _backing = null;
    super._setValueAndNotify(newValue);
  }

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
    final list = _untrackedValue;
    if (newLength == list.length) {
      list.length = newLength;
      return;
    }
    _resize((list) => list.length = newLength);
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
    return _value + other;
  }

  /// The object at the given [index] in the list.
  ///
  /// The [index] must be a valid index of this list,
  /// which means that `index` must be non-negative and
  /// less than [length].
  @override
  E operator [](int index) {
    return _value[index];
  }

  /// Whether the list contains an element equal to [element].
  @override
  bool contains(Object? element) => _value.contains(element);

  /// The first index at or after [start] with an element equal to [element],
  /// or -1 if no element matches.
  @override
  int indexOf(Object? element, [int start = 0]) {
    // A backing List<E>.indexOf can reject queries outside its element type.
    return _value.indexWhere((item) => item == element, start);
  }

  /// Sets the value at the given [index] in the list to [value].
  ///
  /// The [index] must be a valid index of this list,
  /// which means that `index` must be non-negative and
  /// less than [length].
  @override
  void operator []=(int index, E value) {
    _writeSlot(index, value, (list) => list[index] = value);
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
  void add(E element) => _append((list) => list.add(element));

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
    if (_isEmptyCollection(iterable)) return _untrackedValue.addAll(iterable);
    _resize((list) => list.addAll(iterable));
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
    return _value.singleWhere(test, orElse: orElse);
  }

  /// Checks that this iterable has only one element, and returns that element.
  ///
  /// Throws a [StateError] if `this` is empty or has more than one element.
  /// This operation will not iterate past the second element.
  @override
  E get single {
    return _value.single;
  }

  /// The first element.
  ///
  /// Throws a [StateError] if `this` is empty.
  /// Otherwise returns the first element in the iteration order,
  /// equivalent to `this.elementAt(0)`.
  @override
  E get first {
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
    return _value.sublist(start, end);
  }

  /// Copies the elements into a new [ListSignal] of [R] instances.
  ///
  /// This reads the entire list before returning. An element of another
  /// type can throw while building the copy.
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
    _writeSlot(0, value, (list) => list.first = value);
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
    _writeSlot(
      _untrackedValue.length - 1,
      value,
      (list) => list.last = value,
    );
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
    _resize((list) => list.clear());
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
    final list = _untrackedValue;
    if (start == end || 0 > start || start > end || end > list.length) {
      // For an invalid range, the backing list throws its own error.
      return list.fillRange(start, end, fillValue);
    }
    final backing = _backingOf(list);
    if (backing == _ListBacking.unmodifiable) {
      return list.fillRange(start, end, fillValue);
    }
    void write(List<E> list) => list.fillRange(start, end, fillValue);
    if (backing == _ListBacking.opaque) {
      // A custom list can change a slot even when the input matches its value.
      return _writeRange(start, end, write);
    }
    final typed = backing == _ListBacking.typed;
    if (typed && fillValue == null) return write(list);
    if (typed && !trackPreviousValue) {
      // A typed list stores the same converted value in every slot. If
      // the range is already uniform, only its first slot needs a recheck.
      final first = list[start];
      var index = start + 1;
      while (index < end && identical(first, list[index])) {
        index++;
      }
      if (index == end && identical(first, fillValue)) {
        return list.fillRange(start, end, fillValue);
      }
      return _mutate(
        write,
        slotChanged: () => index != end || !identical(first, list[start]),
        failedSlotChanged: () => false,
      );
    }
    // Find the first slot that differs from [fillValue]. Without one, the
    // call changes nothing, so it needs no copy.
    var index = start;
    while (index < end && identical(_readSlot(list, index), fillValue)) {
      index++;
    }
    if (index == end) return list.fillRange(start, end, fillValue);
    _mutate(
      write,
      bulkCheck: typed
          ? (list, previous) => previous == null
                ? _saveRange(list, start, end)
                : () => _rangeChanged(list, start, end - start, previous, start)
          : null,
      slotChanged: typed ? null : () => true,
      // Native lists reject a fill before writing any slots.
      failedSlotChanged: () => false,
    );
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
    final list = _untrackedValue;
    // At the end, an insert is an add, so it can use the cheaper undo step.
    if (trackPreviousValue &&
        index == list.length &&
        list.runtimeType == _defaultListType) {
      return _append((list) => list.insert(index, element));
    }
    _pointResize(
      (list) => list.insert(index, element),
      undo: trackPreviousValue ? (list) => _withoutSlot(list, index) : null,
    );
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
    if (_isEmptyCollection(iterable)) {
      return _untrackedValue.insertAll(index, iterable);
    }
    _resize((list) => list.insertAll(index, iterable));
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
    return _resize((list) => list.remove(element));
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
    return _removeSlot(index, (list) => list.removeAt(index));
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
    return _removeSlot(_untrackedValue.length - 1, (list) => list.removeLast());
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
    if (start == end) return _untrackedValue.removeRange(start, end);
    _resize((list) => list.removeRange(start, end));
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
    _resize((list) => list.removeWhere(test));
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
    if (_isEmptyCollection(replacements)) {
      if (start == end) {
        return _untrackedValue.replaceRange(start, end, replacements);
      }
      // It only removes, so the length tells whether it changed the list.
      return _resize((list) => list.replaceRange(start, end, replacements));
    }
    if ((replacements is List || replacements is Set) &&
        replacements.length != end - start) {
      // A success always changes the length, so it tells the change.
      return _resize((list) => list.replaceRange(start, end, replacements));
    }
    _writeRange(
      start,
      end,
      (list) => list.replaceRange(start, end, replacements),
      resizes: true,
    );
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
    _resize((list) => list.retainWhere(test));
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
    final list = _untrackedValue;
    if (iterable is List<E> && _hasStableLength(iterable)) {
      if (iterable.isEmpty) return list.setAll(index, iterable);
      _writeRange(
        index,
        index + min(iterable.length, max(0, list.length - index)),
        (list) => list.setAll(index, iterable),
      );
      return;
    }
    // Lazy iterables can run caller code on each read.
    _mutate(
      (list) => list.setAll(index, iterable),
      bulkCheck: _bulkChangeCheck,
      comparesAllElements: true,
    );
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
    final list = _untrackedValue;
    if (start == end ||
        (list.runtimeType == _defaultListType &&
            iterable is List<E> &&
            (identical(iterable, const <Never>[]) ||
                (_hasStableLength(iterable) && iterable.isEmpty)))) {
      return list.setRange(start, end, iterable, skipCount);
    }
    _writeRange(
      start,
      end,
      (list) => list.setRange(start, end, iterable, skipCount),
    );
  }

  /// Shuffles the elements of this list randomly.
  /// ```dart
  /// final numbers = <int>[1, 2, 3, 4, 5];
  /// numbers.shuffle();
  /// print(numbers); // [1, 3, 4, 5, 2] OR some other random result.
  /// ```
  @override
  void shuffle([Random? random]) {
    _mutate((list) => list.shuffle(random), bulkCheck: _bulkChangeCheck);
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
    _mutate((list) => list.sort(compare), bulkCheck: _bulkChangeCheck);
  }

  @override
  String toString() =>
      '''ListSignal<$E>(value: $_value, previousValue: $_previousDescription)''';

  @override
  int _lengthOf(List<E> list) => list.length;

  @override
  List<E> _copyPrevious(List<E> list) => List<E>.of(list);

  @override
  bool Function(List<E>, List<E>) get _restoredContentsDiffer =>
      _elementsDiffer;

  bool Function() _bulkChangeCheck(List<E> list, List<E>? previous) {
    final before = previous ?? List<E>.of(list);
    return () => _elementsDiffer(list, before);
  }

  bool _elementsDiffer(List<E> list, List<E> before) =>
      !const ListEquality<Object?>(IdentityEquality()).equals(before, list);

  /// Runs [write], which adds one element at the end, with the undo step
  /// that removes it. Private, so an override of [add] is not called.
  void _append(void Function(List<E>) write) {
    _pointResize(
      write,
      undo: trackPreviousValue
          ? (list) => _copyPrevious(list)..removeLast()
          : null,
      savePreviousOnNestedWrite: trackPreviousValue,
    );
  }

  R _resize<R>(R Function(List<E>) write) {
    final list = _mutating;
    // Without an enclosing copy, a nested resize checks its own changes.
    final needsCheck =
        list != null &&
        _mutatingPrevious == null &&
        identical(list, _untrackedValue) &&
        _backingOf(list) == _ListBacking.opaque;
    return _mutate(
      write,
      failedResizeChanged: _elementsDiffer,
      failedSlotChanged: needsCheck ? _saveRange(list, 0, list.length) : null,
    );
  }

  @pragma('vm:prefer-inline')
  R _pointResize<R>(
    R Function(List<E>) write, {
    List<E> Function(List<E>)? undo,
    bool savePreviousOnNestedWrite = false,
  }) {
    final list = _untrackedValue;
    if ((_backing ?? _backingOf(list)) != _ListBacking.opaque ||
        (!trackPreviousValue && _castListTypes.contains(list.runtimeType))) {
      return _mutate(write, backing: list, undo: undo);
    }
    return _opaquePointResize(list, write, undo, savePreviousOnNestedWrite);
  }

  R _opaquePointResize<R>(
    List<E> list,
    R Function(List<E>) write,
    List<E> Function(List<E>)? undo,
    bool savePreviousOnNestedWrite,
  ) {
    if (identical(_mutating, list) && _mutatingPrevious != null) {
      // The enclosing mutation checks its copy against the final contents.
      return _mutate(
        write,
        backing: list,
        undo: undo,
        failedResizeChanged: _elementsDiffer,
      );
    }
    // A custom resize can change any slot. Share the snapshot between the
    // change check and the history reads during and after the write.
    final (before, readable) = untracked(() => _saveResize(list));
    List<E> restorePrevious(List<E> _) => before.cast<E>();
    final restore = trackPreviousValue && readable ? restorePrevious : null;
    return _mutate(
      write,
      backing: list,
      undo: restore ?? undo,
      slotChanged: () =>
          untracked(() => _rangeChanged(list, 0, before.length, before, 0)),
      undoDuringWrite: restore,
      copyPreviousOnNestedWrite: savePreviousOnNestedWrite ? restore : null,
    );
  }

  E _removeSlot(int index, E Function(List<E>) write) {
    if (!trackPreviousValue) return _pointResize(write);
    late E removed;
    return _pointResize(
      (list) => removed = write(list),
      undo: (list) => _withElementAt(list, index, removed),
    );
  }

  late final Type _defaultListType = <E>[].runtimeType;
  late final Type _fixedListType = List<E>.empty().runtimeType;
  late final Type _unmodifiableListType = List<E>.unmodifiable(const [])
      .runtimeType;

  // Exact SDK types keep custom lists on the snapshot path.
  static final _nativeNumericListTypes = <Type>{
    <int>[].runtimeType,
    <int?>[].runtimeType,
    <double>[].runtimeType,
    <double?>[].runtimeType,
    <num>[].runtimeType,
    <num?>[].runtimeType,
  };

  // Keep length-only resizes for SDK casts from broad element types when
  // history is off. The view can contain elements that fail a cast on read.
  late final _castListTypes = <Type>{
    List.castFrom<Object, E>(const []).runtimeType,
    List.castFrom<Object?, E>(const []).runtimeType,
    List.castFrom<dynamic, E>(const []).runtimeType,
    List.castFrom<num, E>(const []).runtimeType,
    List.castFrom<num?, E>(const []).runtimeType,
  };

  bool _hasStableLength(List<E> list) {
    final type = list.runtimeType;
    return type == _defaultListType ||
        type == _fixedListType ||
        type == _unmodifiableListType ||
        list is TypedData;
  }

  static final Type? _unmodifiableBufferType = _findUnmodifiableBufferType();

  static Type? _findUnmodifiableBufferType() {
    final bytes = Uint8List(0);
    final type = bytes.asUnmodifiableView().buffer.runtimeType;
    return type == bytes.buffer.runtimeType ? null : type;
  }

  _ListBacking? _backing;

  _ListBacking _backingOf(List<E> list) {
    if (!identical(list, _untrackedValue)) return _classifyBacking(list);
    if (_backing case final backing?) return backing;
    final backing = _classifyBacking(list);
    if (identical(list, _untrackedValue)) _backing = backing;
    return backing;
  }

  _ListBacking _classifyBacking(List<E> list) {
    if (list case final TypedData data) {
      // SDKs with a distinct read-only buffer type expose it on typed views.
      return data.buffer.runtimeType == _unmodifiableBufferType
          ? _ListBacking.unmodifiable
          : _ListBacking.typed;
    }
    final type = list.runtimeType;
    // Some backends use the same runtime type for all native lists.
    if (type == _defaultListType ||
        type == _fixedListType ||
        _nativeNumericListTypes.contains(type)) {
      return _ListBacking.plain;
    }
    if (type == _unmodifiableListType || type == UnmodifiableListView<E>) {
      return _ListBacking.unmodifiable;
    }
    return _ListBacking.opaque;
  }

  /// [list] with [element] back at [index]. It is built at its final length:
  /// a copy and then an insert can grow the backing array to twice its size.
  /// A default list is built in one pass by index. Another list is read once
  /// with one iterator, because its indexed reads can be slow.
  List<E> _withElementAt(List<E> list, int index, E element) {
    if (list.runtimeType == _defaultListType) {
      return List<E>.generate(
        list.length + 1,
        (i) => i < index ? list[i] : (i == index ? element : list[i - 1]),
      );
    }
    final elements = list.iterator;
    // `List.generate` calls its generator in increasing index order.
    return List<E>.generate(list.length + 1, (i) {
      if (i == index) return element;
      elements.moveNext();
      return elements.current;
    });
  }

  /// [list] without the slot at [index], built like [_withElementAt].
  List<E> _withoutSlot(List<E> list, int index) {
    if (list.runtimeType == _defaultListType) {
      return List<E>.generate(
        list.length - 1,
        (i) => i < index ? list[i] : list[i + 1],
      );
    }
    final elements = list.iterator;
    return List<E>.generate(list.length - 1, (i) {
      elements.moveNext();
      if (i == index) elements.moveNext();
      return elements.current;
    });
  }

  // A cast view can reject a read even when the backing write is valid.
  static final _unreadable = Object();

  Object? _readSlot(List<E> list, int index) {
    try {
      return list[index];
    } on Object {
      return _unreadable;
    }
  }

  (List<Object?>, bool) _saveResize(List<E> list) {
    final length = list.length;
    final before = List<Object?>.filled(length, null, growable: true);
    var index = 0;
    try {
      final elements = list.iterator;
      while (index < length && elements.moveNext()) {
        before[index] = elements.current;
        index++;
      }
    } on Object {
      // Try each remaining slot so a single unreadable entry cannot hide
      // a change elsewhere or block a valid write.
    }
    var readable = true;
    for (; index < length; index++) {
      final value = _readSlot(list, index);
      if (identical(value, _unreadable)) readable = false;
      before[index] = value;
    }
    return (before, readable);
  }

  /// Whether a slot of `list` from [start] differs from [before], where
  /// `before[offset + i]` held slot `start + i`.
  bool _rangeChanged(
    List<E> list,
    int start,
    int count,
    List<Object?> before,
    int offset,
  ) {
    for (var i = 0; i < count; i++) {
      if (!identical(before[offset + i], _readSlot(list, start + i))) {
        return true;
      }
    }
    return false;
  }

  bool Function() _saveRange(List<E> list, int start, int end) {
    final count = end - start;
    final before = List<Object?>.filled(count, null);
    for (var i = 0; i < count; i++) {
      before[i] = _readSlot(list, start + i);
    }
    return () => _rangeChanged(list, start, count, before, 0);
  }

  /// Runs [write], which can change only the slots from [start] to [end].
  /// With history, the slots are compared with the history copy. Without
  /// it, only those slots are saved.
  ///
  /// Set [resizes] when [write] can change the length, so a write that
  /// fails after it moved elements is still found.
  void _writeRange(
    int start,
    int end,
    void Function(List<E>) write, {
    bool resizes = false,
  }) {
    _mutate(
      write,
      bulkCheck: (list, previous) {
        final count = 0 <= start && start <= end && end <= list.length
            ? end - start
            : 0;
        if (previous != null) {
          return () => _rangeChanged(list, start, count, previous, start);
        }
        return _saveRange(list, start, start + count);
      },
      failedResizeChanged: resizes ? _elementsDiffer : null,
    );
  }

  void _writeSlot(int index, E value, void Function(List<E>) write) {
    final list = _untrackedValue;
    final valid = index >= 0 && index < list.length;
    final old = valid ? list[index] : null;
    if (valid && identical(old, value)) return write(list);
    List<E> restorePrevious(List<E> list) =>
        _copyPrevious(list)..[index] = old as E;
    final undo = trackPreviousValue ? restorePrevious : null;
    _mutate(
      write,
      slotChanged: () => valid && !identical(old, list[index]),
      // A typed list rejects a write before it changes the slot. Reading
      // a SIMD slot again would box the same value in a different object.
      failedSlotChanged: list is TypedData ? () => false : null,
      undo: undo,
      undoDuringWrite: valid ? undo : null,
    );
  }

  @override
  // ignore: overridden_fields
  final _id = ReactiveName.nameFor('ListSignal');
}
