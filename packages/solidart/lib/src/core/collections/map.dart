part of '../core.dart';

/// {@template map-signal}
/// `MapSignal` makes easier interacting with maps in a reactive context.
///
/// ```dart
/// final map = MapSignal({'first': 1});
///
/// Effect((_) {
///   print(map['first']);
/// }); // prints 1
///
/// map['first'] = 100; // the effect prints 100
/// ```
/// {@endtemplate}
class MapSignal<K, V> extends Signal<Map<K, V>> with MapMixin<K, V> {
  /// {@macro map-signal}
  factory MapSignal(
    Map<K, V> initialValue, {
    SignalOptions<Map<K, V>>? options,
  }) {
    final name = options?.name ?? ReactiveContext.main.nameFor('MapSignal');
    final effectiveOptions =
        (options ?? SignalOptions<Map<K, V>>(name: name)).copyWith(name: name);
    return MapSignal._internal(
      initialValue: Map<K, V>.of(initialValue),
      options: effectiveOptions,
      name: name,
    );
  }

  MapSignal._internal({
    required super.initialValue,
    required super.name,
    required super.options,
  }) : super._internal();

  @override
  void _setValue(Map<K, V> newValue) {
    if (_areEqual(_value, newValue)) {
      return;
    }
    _setPreviousValue(Map<K, V>.of(_value));
    _value = newValue;
    _notifyChanged();
  }

  @override
  Map<K, V> updateValue(Map<K, V> Function(Map<K, V> value) callback) =>
      value = callback(Map<K, V>.of(_value));

  @override
  bool _areEqual(Map<K, V>? oldValue, Map<K, V>? newValue) {
    // skip if the value are equals
    if (options.equals) {
      return MapEquality<K, V>().equals(oldValue, newValue);
    }

    // return the [comparator] result
    return options.comparator!(oldValue, newValue);
  }

  /// The value for the given [key], or `null` if [key] is not in the map.
  ///
  /// Some maps allow `null` as a value.
  /// For those maps, a lookup using this operator cannot distinguish between a
  /// key not being in the map, and the key being there with a `null` value.
  /// Methods like [containsKey] or [putIfAbsent] can be used if the distinction
  /// is important.
  @override
  V? operator [](Object? key) {
    _reportObserved();

    // Wrap in parentheses to avoid parsing conflicts when casting the key
    return _value[(key as K?)];
  }

  /// Associates the [key] with the given [value].
  ///
  /// If the key was already in the map, its associated value is changed.
  /// Otherwise the key/value pair is added to the map.
  @override
  void operator []=(K key, V value) {
    final oldValue = _value[key];
    if (!_value.containsKey(key) || value != oldValue) {
      _setPreviousValue(Map<K, V>.of(_value));
      _value[key] = value;
      _notifyChanged();
    }
  }

  /// Removes all entries from the map.
  ///
  /// After this, the map is empty.
  /// ```dart
  /// final planets = <int, String>{1: 'Mercury', 2: 'Venus', 3: 'Earth'};
  /// planets.clear(); // {}
  /// ```
  @override
  void clear() {
    if (_value.isNotEmpty) {
      _setPreviousValue(Map<K, V>.of(_value));
      _value.clear();
      _notifyChanged();
    }
  }

  /// The keys of the Map.
  ///
  /// The returned iterable has efficient `length` and `contains` operations,
  /// based on [length] and [containsKey] of the map.
  ///
  /// The order of iteration is defined by the individual `Map` implementation,
  /// but must be consistent between changes to the map.
  ///
  /// Modifying the map while iterating the keys may break the iteration.
  @override
  Iterable<K> get keys {
    _reportObserved();
    return _value.keys;
  }

  /// The values of the Map.
  ///
  /// The values are iterated in the order of their corresponding keys.
  /// This means that iterating [keys] and [values] in parallel will
  /// provide matching pairs of keys and values.
  ///
  /// The returned iterable has an efficient `length` method based on the
  /// [length] of the map. Its [Iterable.contains] method is based on
  /// `==` comparison.
  ///
  /// Modifying the map while iterating the values may break the iteration.
  @override
  Iterable<V> get values {
    _reportObserved();
    return _value.values;
  }

  /// Removes [key] and its associated value, if present, from the map.
  ///
  /// Returns the value associated with `key` before it was removed.
  /// Returns `null` if `key` was not in the map.
  ///
  /// Note that some maps allow `null` as a value,
  /// so a returned `null` value doesn't always mean that the key was absent.
  /// ```dart
  /// final terrestrial = <int, String>{1: 'Mercury', 2: 'Venus', 3: 'Earth'};
  /// final removedValue = terrestrial.remove(2); // Venus
  /// print(terrestrial); // {1: Mercury, 3: Earth}
  /// ```
  @override
  V? remove(Object? key) {
    V? value;
    if (_value.containsKey(key)) {
      _setPreviousValue(Map<K, V>.of(_value));
      value = _value.remove(key);
      _notifyChanged();
    }
    return value;
  }

  /// Provides a view of this map as having [RK] keys and [RV] instances,
  /// if necessary.
  ///
  /// If this map is already a `Map<RK, RV>`, it is returned unchanged.
  ///
  /// If this set contains only keys of type [RK] and values of type [RV],
  /// all read operations will work correctly.
  /// If any operation exposes a non-[RK] key or non-[RV] value,
  /// the operation will throw instead.
  ///
  /// Entries added to the map must be valid for both a `Map<K, V>` and a
  /// `Map<RK, RV>`.
  ///
  /// Methods which accept `Object?` as argument,
  /// like [containsKey], [remove] and [operator []],
  /// will pass the argument directly to the this map's method
  /// without any checks.
  /// That means that you can do `mapWithStringKeys.cast<int,int>().remove("a")`
  /// successfully, even if it looks like it shouldn't have any effect.
  @override
  Map<RK, RV> cast<RK, RV>() => MapSignal(_value.cast<RK, RV>());

  /// The number of key/value pairs in the map.
  @override
  int get length {
    _reportObserved();
    return _value.length;
  }

  /// Whether there is no key/value pair in the map.
  @override
  bool get isEmpty {
    _reportObserved();
    return _value.isEmpty;
  }

  /// Whether there is at least one key/value pair in the map.
  @override
  bool get isNotEmpty {
    _reportObserved();
    return _value.isNotEmpty;
  }

  /// Whether this map contains the given [key].
  ///
  /// Returns true if any of the keys in the map are equal to `key`
  /// according to the equality used by the map.
  /// ```dart
  /// final moonCount = <String, int>{'Mercury': 0, 'Venus': 0, 'Earth': 1,
  ///   'Mars': 2, 'Jupiter': 79, 'Saturn': 82, 'Uranus': 27, 'Neptune': 14 };
  /// final containsUranus = moonCount.containsKey('Uranus'); // true
  /// final containsPluto = moonCount.containsKey('Pluto'); // false
  /// ```
  @override
  bool containsKey(Object? key) {
    _reportObserved();
    return _value.containsKey(key);
  }

  /// Whether this map contains the given [value].
  ///
  /// Returns true if any of the values in the map are equal to `value`
  /// according to the `==` operator.
  /// ```dart
  /// final moonCount = <String, int>{'Mercury': 0, 'Venus': 0, 'Earth': 1,
  ///   'Mars': 2, 'Jupiter': 79, 'Saturn': 82, 'Uranus': 27, 'Neptune': 14 };
  /// final moons3 = moonCount.containsValue(3); // false
  /// final moons82 = moonCount.containsValue(82); // true
  /// ```
  @override
  bool containsValue(Object? value) {
    _reportObserved();
    return _value.containsValue(value);
  }

  /// The map entries of the Map.
  @override
  Iterable<MapEntry<K, V>> get entries {
    _reportObserved();
    return _value.entries;
  }

  /// Adds all key/value pairs of [newEntries] to this map.
  ///
  /// If a key of [newEntries] is already in this map,
  /// the corresponding value is overwritten.
  ///
  /// The operation is equivalent to doing `this[entry.key] = entry.value`
  /// for each [MapEntry] of the iterable.
  /// ```dart
  /// final planets = <int, String>{1: 'Mercury', 2: 'Venus',
  ///   3: 'Earth', 4: 'Mars'};
  /// final gasGiants = <int, String>{5: 'Jupiter', 6: 'Saturn'};
  /// final iceGiants = <int, String>{7: 'Uranus', 8: 'Neptune'};
  /// planets.addEntries(gasGiants.entries);
  /// planets.addEntries(iceGiants.entries);
  /// print(planets);
  /// // {1: Mercury, 2: Venus, 3: Earth, 4: Mars, 5: Jupiter, 6: Saturn,
  /// //  7: Uranus, 8: Neptune}
  /// ```
  @override
  void addEntries(Iterable<MapEntry<K, V>> newEntries) {
    if (newEntries.isNotEmpty) {
      _setPreviousValue(Map<K, V>.of(_value));
      _value.addEntries(newEntries);
      _notifyChanged();
    }
  }

  /// Adds all key/value pairs of [other] to this map.
  ///
  /// If a key of [other] is already in this map, its value is overwritten.
  ///
  /// The operation is equivalent to doing `this[key] = value` for each key
  /// and associated value in other. It iterates over [other], which must
  /// therefore not change during the iteration.
  /// ```dart
  /// final planets = <int, String>{1: 'Mercury', 2: 'Earth'};
  /// planets.addAll({5: 'Jupiter', 6: 'Saturn'});
  /// print(planets); // {1: Mercury, 2: Earth, 5: Jupiter, 6: Saturn}
  /// ```
  @override
  void addAll(Map<K, V> other) {
    if (other.isNotEmpty) {
      _setPreviousValue(Map<K, V>.of(_value));
      _value.addAll(other);
      _notifyChanged();
    }
  }

  /// Look up the value of [key], or add a new entry if it isn't there.
  ///
  /// Returns the value associated to [key], if there is one.
  /// Otherwise calls [ifAbsent] to get a new value, associates [key] to
  /// that value, and then returns the new value.
  /// ```dart
  /// final diameters = <num, String>{1.0: 'Earth'};
  /// final otherDiameters = <double, String>{0.383: 'Mercury', 0.949: 'Venus'};
  ///
  /// for (final item in otherDiameters.entries) {
  ///   diameters.putIfAbsent(item.key, () => item.value);
  /// }
  /// print(diameters); // {1.0: Earth, 0.383: Mercury, 0.949: Venus}
  ///
  /// // If the key already exists, the current value is returned.
  /// final result = diameters.putIfAbsent(0.383, () => 'Random');
  /// print(result); // Mercury
  /// print(diameters); // {1.0: Earth, 0.383: Mercury, 0.949: Venus}
  /// ```
  /// Calling [ifAbsent] must not add or remove keys from the map.
  @override
  V putIfAbsent(K key, V Function() ifAbsent) {
    if (_value.containsKey(key)) {
      _reportObserved();
      return _value[key] as V;
    }
    _setPreviousValue(Map<K, V>.of(_value));
    _value[key] = ifAbsent();
    _notifyChanged();
    return _value[key] as V;
  }

  /// Removes all entries of this map that satisfy the given [test].
  /// ```dart
  /// final terrestrial = <int, String>{1: 'Mercury', 2: 'Venus', 3: 'Earth'};
  /// terrestrial.removeWhere((key, value) => value.startsWith('E'));
  /// print(terrestrial); // {1: Mercury, 2: Venus}
  /// ```
  @override
  void removeWhere(bool Function(K key, V value) test) {
    final keysToRemove = <K>[];
    for (final key in keys) {
      if (test(key, this[key] as V)) keysToRemove.add(key);
    }
    if (keysToRemove.isNotEmpty) {
      _setPreviousValue(Map<K, V>.of(_value));
    }
    for (final key in keysToRemove) {
      _value.remove(key);
    }
    if (keysToRemove.isNotEmpty) {
      _notifyChanged();
    }
  }

  /// Updates the value for the provided [key].
  ///
  /// Returns the new value associated with the key.
  ///
  /// If the key is present, invokes [update] with the current value and stores
  /// the new value in the map.
  ///
  /// If the key is not present and [ifAbsent] is provided, calls [ifAbsent]
  /// and adds the key with the returned value to the map.
  ///
  /// If the key is not present, [ifAbsent] must be provided.
  /// ```dart
  /// final planetsFromSun = <int, String>{1: 'Mercury', 2: 'unknown',
  ///   3: 'Earth'};
  /// // Update value for known key value 2.
  /// planetsFromSun.update(2, (value) => 'Venus');
  /// print(planetsFromSun); // {1: Mercury, 2: Venus, 3: Earth}
  ///
  /// final largestPlanets = <int, String>{1: 'Jupiter', 2: 'Saturn',
  ///   3: 'Neptune'};
  /// // Key value 8 is missing from list, add it using [ifAbsent].
  /// largestPlanets.update(8, (value) => 'New', ifAbsent: () => 'Mercury');
  /// print(largestPlanets); // {1: Jupiter, 2: Saturn, 3: Neptune, 8: Mercury}
  /// ```
  @override
  V update(K key, V Function(V value) update, {V Function()? ifAbsent}) {
    if (_value.containsKey(key)) {
      final oldValue = _value[key];
      final newValue = update(_value[key] as V);
      if (oldValue != newValue) {
        _setPreviousValue(Map<K, V>.of(_value));
        _value[key] = newValue;
      }
      return _value[key] as V;
    }
    if (ifAbsent != null) {
      _setPreviousValue(Map<K, V>.of(_value));
      return _value[key] = ifAbsent();
    }
    throw ArgumentError.value(key, 'key', 'Key not in map.');
  }

  /// Updates all values.
  ///
  /// Iterates over all entries in the map and updates them with the result
  /// of invoking [update].
  /// ```dart
  /// final terrestrial = <int, String>{1: 'Mercury', 2: 'Venus', 3: 'Earth'};
  /// terrestrial.updateAll((key, value) => value.toUpperCase());
  /// print(terrestrial); // {1: MERCURY, 2: VENUS, 3: EARTH}
  /// ```
  @override
  void updateAll(V Function(K key, V value) update) {
    final changes = <K, V>{};
    for (final key in this.keys) {
      final oldValue = _value[key];
      final newValue = update(key, _value[key] as V);
      if (oldValue != newValue) {
        changes[key] = newValue;
      }
    }
    if (changes.isNotEmpty) {
      _setPreviousValue(Map<K, V>.of(_value));
      for (final key in this.keys) {
        _value[key] = changes[key] as V;
      }
      _notifyChanged();
    }
  }

  @override
  String toString() =>
      '''MapSignal<$K, $V>(value: $_value, previousValue: $_previousValue, options; $options)''';

  void _notifyChanged() {
    _reportChanged();
    _notifyListeners();
    _notifySignalUpdate();
  }
}
