part of '../core.dart';

/// {@template list-signal}
/// `SetSignal` makes easier interacting with sets in a reactive context.
///
/// ```dart
/// final set = SetSignal([1]);
///
/// createEffect((_) {
///   print(set.first);
/// }); // prints 1
///
/// set[0] = 100; // the effect prints 100
/// ```
/// {@endtemplate}
class SetSignal<E> extends ReadSignal<Set<E>> with SetMixin<E> {
  /// {@macro list-signal}
  SetSignal(Iterable<E>? initialValue, {super.options})
      : name = options?.name ?? ReactiveContext.main.nameFor('ListSignal'),
        super(Set.of(initialValue ?? []));

  @override
  // ignore: overridden_fields
  final String name;

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
    _setPreviousValue(Set.of(_value));
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
    _reportObserved();
    return _value.contains(element);
  }

  /// An iterator that iterates over the elements of this set.
  ///
  /// The order of iteration is defined by the individual `Set` implementation,
  /// but must be consistent between changes to the set.
  @override
  Iterator<E> get iterator {
    _reportObserved();
    return _value.iterator;
  }

  /// Returns the number of elements in the iterable.
  ///
  /// This is an efficient operation that doesn't require iterating through
  /// the elements.
  @override
  int get length {
    _reportObserved();
    return _value.length;
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
    _reportObserved();
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
      _setPreviousValue(Set.of(_value));
      _value.remove(value);
      _notifyChanged();
      didRemove = true;
    }

    return didRemove;
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
    _reportObserved();
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
      _setPreviousValue(Set.of(_value));
      _value.clear();
      _notifyChanged();
    }
  }

  void _notifyChanged() {
    _reportChanged();
    _notifyListeners();
  }
}
