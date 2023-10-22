// ignore_for_file: public_member_api_docs
part of '../core.dart';

/// {@template list-signal}
/// `ListSignal` makes easier interacting with lists in a reactive context.
///
/// ```dart
/// final list = ListSignal([1]);
///
/// createEffect((_) {
///   print(list.first);
/// }); // prints 1
///
/// list[0] = 100; // the effect prints 100
/// ```
/// {@endtemplate}
class ListSignal<T> extends ReadSignal<List<T>> with ListMixin<T> {
  /// {@macro list-signal}
  ListSignal(Iterable<T>? initialValue, {super.options})
      : name = options?.name ?? ReactiveContext.main.nameFor('ListSignal'),
        super(List.of(initialValue ?? []));

  @override
  // ignore: overridden_fields
  final String name;

  @override
  int get length {
    _reportObserved();
    return _value.length;
  }

  @override
  set length(int value) {
    if (value == _value.length) return;
    _value.length = value;
    _notifyChanged();
  }

  @override
  T elementAt(int index) {
    _reportObserved();
    return _value.elementAt(index);
  }

  @override
  List<T> operator +(List<T> other) {
    _reportObserved();
    return _value + other;
  }

  @override
  T operator [](int index) {
    _reportObserved();
    return _value[index];
  }

  @override
  void operator []=(int index, T value) {
    final oldValue = _value[index];

    if (oldValue != value) {
      _previousValue = List.of(_value);
      _value[index] = value;
      _notifyChanged();
    }
  }

  @override
  void add(T element) {
    _previousValue = List.of(_value);
    _value.add(element);
    _notifyChanged();
  }

  @override
  void addAll(Iterable<T> iterable) {
    if (iterable.isNotEmpty) {
      _previousValue = List.of(_value);
      _value.addAll(iterable);
      _notifyChanged();
    }
  }

  @override
  Iterator<T> get iterator {
    _reportObserved();
    return _value.iterator;
  }

  @override
  int lastIndexWhere(bool Function(T element) test, [int? start]) {
    _reportObserved();
    return _value.lastIndexWhere(test, start);
  }

  @override
  T lastWhere(bool Function(T element) test, {T Function()? orElse}) {
    _reportObserved();
    return _value.lastWhere(test, orElse: orElse);
  }

  @override
  T firstWhere(bool Function(T element) test, {T Function()? orElse}) {
    _reportObserved();
    return _value.firstWhere(test, orElse: orElse);
  }

  @override
  T singleWhere(bool Function(T element) test, {T Function()? orElse}) {
    _reportObserved();
    return _value.singleWhere(test, orElse: orElse);
  }

  @override
  T get single {
    _reportObserved();
    return _value.single;
  }

  @override
  T get first {
    _reportObserved();
    return _value.first;
  }

  @override
  T get last {
    _reportObserved();
    return _value.last;
  }

  @override
  List<T> sublist(int start, [int? end]) {
    _reportObserved();
    return _value.sublist(start, end);
  }

  @override
  List<R> cast<R>() => ListSignal(_value.cast<R>());

  @override
  List<T> toList({bool growable = true}) {
    _reportObserved();
    return _value.toList(growable: growable);
  }

  @override
  set first(T value) {
    final oldValue = _value.first;
    if (oldValue != value) {
      _previousValue = List.of(_value);
      _value.first = value;
      _notifyChanged();
    }
  }

  @override
  set last(T value) {
    final oldValue = _value.last;
    if (oldValue != value) {
      _previousValue = List.of(_value);
      _value.last = value;
      _notifyChanged();
    }
  }

  @override
  void clear() {
    if (_value.isNotEmpty) {
      _previousValue = List.of(_value);
      _value.clear();
      _notifyChanged();
    }
  }

  @override
  void fillRange(int start, int end, [T? fill]) {
    if (end > start) {
      _previousValue = List.of(_value);
      _value.fillRange(start, end, fill);
      _notifyChanged();
    }
  }

  @override
  void insert(int index, T element) {
    _previousValue = List.of(_value);
    _value.insert(index, element);
    _notifyChanged();
  }

  @override
  void insertAll(int index, Iterable<T> iterable) {
    if (iterable.isNotEmpty) {
      _previousValue = List.of(_value);
      _value.insertAll(index, iterable);
      _notifyChanged();
    }
  }

  @override
  bool remove(Object? element) {
    var didRemove = false;
    final index = _value.indexOf(element as T);
    if (index >= 0) {
      _previousValue = List.of(_value);
      _value.removeAt(index);
      _notifyChanged();
      didRemove = true;
    }

    return didRemove;
  }

  @override
  T removeAt(int index) {
    _previousValue = List.of(_value);

    final removed = _value.removeAt(index);
    _notifyChanged();

    return removed;
  }

  @override
  T removeLast() {
    _previousValue = List.of(_value);

    final removed = _value.removeLast();
    _notifyChanged();

    return removed;
  }

  @override
  void removeRange(int start, int end) {
    if (end > start) {
      _previousValue = List.of(_value);
      _value.removeRange(start, end);
      _notifyChanged();
    }
  }

  @override
  void removeWhere(bool Function(T element) test) {
    final removedIndexes = <int>[];
    for (var i = _value.length - 1; i >= 0; --i) {
      final element = _value[i];
      if (test(element)) {
        removedIndexes.add(i);
      }
    }
    if (removedIndexes.isNotEmpty) {
      _previousValue = List.of(_value);
      for (final index in removedIndexes) {
        _value.removeAt(index);
      }
      _notifyChanged();
    }
  }

  @override
  void replaceRange(int start, int end, Iterable<T> newContents) {
    if (end > start || newContents.isNotEmpty) {
      _previousValue = List.of(_value);
      _value.replaceRange(start, end, newContents);
      _notifyChanged();
    }
  }

  @override
  void retainWhere(bool Function(T element) test) {
    final removedIndexes = <int>[];
    for (var i = _value.length - 1; i >= 0; --i) {
      final element = _value[i];
      if (!test(element)) {
        removedIndexes.add(i);
      }
    }
    if (removedIndexes.isNotEmpty) {
      _previousValue = List.of(_value);
      for (final index in removedIndexes) {
        _value.removeAt(index);
      }
    }
  }

  @override
  void setAll(int index, Iterable<T> iterable) {
    if (iterable.isNotEmpty) {
      _previousValue = List.of(_value);

      _value.setAll(index, iterable);
      _notifyChanged();
    }
  }

  @override
  void setRange(int start, int end, Iterable<T> iterable, [int skipCount = 0]) {
    if (end > start) {
      _previousValue = List.of(_value);
      _value.setRange(start, end, iterable, skipCount);
      _notifyChanged();
    }
  }

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
        _previousValue = List.of(_value);
        _value = newList;
        _notifyChanged();
      }
    }
  }

  @override
  void sort([int Function(T a, T b)? compare]) {
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
        _previousValue = List.of(_value);
        _value = newList;
        _notifyChanged();
      }
    }
  }

  @override
  String toString() =>
      '''ListSignal<$T>(value: $value, previousValue: $previousValue, options; $options)''';

  void _notifyChanged() {
    _reportChanged();
    _notifyListeners();
  }
}
