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
class MapSignal<K, V> extends Signal<Map<K, V>>
    with MapMixin<K, V>, _CollectionSignal<Map<K, V>> {
  /// {@macro map-signal}
  MapSignal(
    super.initialValue, {

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
  });

  @override
  Map<K, V> updateValue(Map<K, V> Function(Map<K, V> value) callback) =>
      value = callback(Map<K, V>.of(_untrackedValue));

  @override
  bool _compare(Map<K, V>? oldValue, Map<K, V>? newValue) {
    // skip if the value are equals
    if (equals) {
      return MapEquality<K, V>().equals(oldValue, newValue);
    }

    // return the [comparator] result
    return comparator(oldValue, newValue);
  }

  @override
  Map<K, V> get _value {
    final baseline = _replacementBaseline;
    final firstObserver = baseline != null && _internalSignal.subs == null;
    final value = super._value;
    if (baseline != null &&
        reactiveSystem.activeSub != null &&
        identical(value, _mutating) &&
        !disposed) {
      baseline.recordRead(
        _internalSignal.currentValue,
        value,
        _compare,
        _replacementSlotsMatch,
        _readReplacementSlot,
        firstObserver: firstObserver,
      );
    }
    return value;
  }

  @override
  void _setValueAndNotify(Map<K, V> newValue) {
    final baseline = _replacementBaseline;
    final old = _untrackedValue;
    final signal = _internalSignal;
    final committed = signal.currentValue;
    if (baseline == null ||
        !identical(old, _mutating) ||
        !identical(old, committed.safeUnwrap())) {
      super._setValueAndNotify(newValue);
      return;
    }

    reactiveSystem._runThen(() => super._setValueAndNotify(newValue), () {
      // Effects can commit the replacement synchronously. A batch or a
      // lazy computed can leave the comparison until after the backing write.
      if (signal.forceDirty || !identical(signal.currentValue, committed)) {
        return;
      }
      final snapshot = baseline.capture(committed);
      if (!signal.forceDirty && identical(signal.currentValue, committed)) {
        if (baseline.observedChange) {
          // A subscriber read an intermediate change, or a nested write
          // changed a map whose original state could not be copied.
          signal.forceDirty = true;
        } else if (snapshot != null) {
          signal.currentValue = Some(snapshot);
        }
      }
    });
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
    value;

    // Wrap in parentheses to avoid parsing conflicts when casting the key
    return _value[(key as K?)];
  }

  // Only the default map shares key equality with the plain history copy.
  // Its type arguments must match the signal's.
  late final Type _defaultMapType = <K, V>{}.runtimeType;

  bool _canRewindSlot(Map<K, V> map, K key) =>
      _replacementBaseline != null &&
      identical(_mutating, map) &&
      !_internalSignal.forceDirty &&
      map.runtimeType == _defaultMapType &&
      _isValueKey(key);

  /// Associates the [key] with the given [value].
  ///
  /// If the key was already in the map, its associated value is changed.
  /// Otherwise the key/value pair is added to the map.
  @override
  void operator []=(K key, V value) {
    final map = _untrackedValue;
    final old = map[key];
    final defaultMap = trackPreviousValue && map.runtimeType == _defaultMapType;
    final rewindable = _canRewindSlot(map, key);
    final sameValue = identical(old, value);
    final present =
        old != null ||
        ((defaultMap || sameValue || rewindable) && map.containsKey(key));
    // An overwrite keeps the caller's key in the undo step. The caller can
    // change a mutable key later, so only an immutable value key is lazy.
    // A new key is stored as it is, so only NaN cannot be undone.
    final lazy = defaultMap && (present ? _isValueKey(key) : !_isNaN(key));
    _mutateUnless(
      sameValue && present,
      (map) => map[key] = value,
      slotChanged: () => !identical(old, map[key]),
      replacementSlot: rewindable
          ? (key: key, value: old, present: present)
          : null,
      undo: lazy
          ? (map) {
              if (present) return _copyPrevious(map)..[key] = old as V;
              // Build the map without the new key. A copy of the map would
              // be sized for a table that may have grown for that key.
              final copy = <K, V>{};
              map.forEach((k, v) {
                if (!identical(k, key)) copy[k] = v;
              });
              return copy;
            }
          : null,
    );
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
    _mutate((map) => map.clear());
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
    value;
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
    value;
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
    final map = _untrackedValue;
    final present = map.containsKey(key);
    return _mutateUnless(
      !present,
      (map) => map.remove(key),
      replacementSlot: present && key is K && _canRewindSlot(map, key)
          ? (key: key, value: map[key], present: true)
          : null,
    );
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
    value;
    return _value.length;
  }

  /// Whether there is no key/value pair in the map.
  @override
  bool get isEmpty {
    value;
    return _value.isEmpty;
  }

  /// Whether there is at least one key/value pair in the map.
  @override
  bool get isNotEmpty {
    value;
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
    value;
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
    this.value;
    return _value.containsValue(value);
  }

  /// The map entries of the Map.
  @override
  Iterable<MapEntry<K, V>> get entries {
    value;
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
    if (_isEmptyCollection(newEntries)) {
      return _untrackedValue.addEntries(newEntries);
    }
    // Even a list can run code each time it is read (for example a view
    // over a lazy iterable), so read [newEntries] only once.
    _mutate((map) => map.addEntries(newEntries), bulkCheck: _bulkChangeCheck);
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
    if (other.isEmpty) return _untrackedValue.addAll(other);
    // Into an empty map, each new key changes the length.
    if (_untrackedValue.isEmpty) return _mutate((map) => map.addAll(other));
    _writeKeys(
      _keysOf(() => other.keys.toList(growable: false)),
      (map) => map.addAll(other),
    );
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
    // A new key changes the length.
    final map = _untrackedValue;
    if (map.containsKey(key)) return map.putIfAbsent(key, ifAbsent);
    final slot = _canRewindSlot(map, key)
        ? (key: key, value: null, present: false)
        : null;
    final deferWrite = _deferCallbackWrite(map, slot);
    return _mutate(
      (map) => map.putIfAbsent(
        key,
        deferWrite ? () => _beforeCallbackWrite(map, ifAbsent()) : ifAbsent,
      ),
      copyReplacementBaseline: equals ? _copyReplacementMap : null,
      replacementSlot: slot,
      deferReplacementWrite: deferWrite,
    );
  }

  /// Removes all entries of this map that satisfy the given [test].
  /// ```dart
  /// final terrestrial = <int, String>{1: 'Mercury', 2: 'Venus', 3: 'Earth'};
  /// terrestrial.removeWhere((key, value) => value.startsWith('E'));
  /// print(terrestrial); // {1: Mercury, 2: Venus}
  /// ```
  @override
  void removeWhere(bool Function(K key, V value) test) {
    final backing = _untrackedValue;
    if (!equals) return _mutate((map) => map.removeWhere(test));
    if (identical(backing, _mutating)) {
      return _mutate(
        (map) => map.removeWhere(test),
        bulkVersion: (length) => length - backing.length,
      );
    }
    // The backing can remove an entry before calling the next predicate.
    // Keep the accepted entries until a read or replacement needs them.
    final removed = <Object?>[];
    _mutate(
      (map) => map.removeWhere((key, value) {
        final remove = test(key, value);
        if (remove) {
          removed
            ..add(key)
            ..add(value);
        }
        return remove;
      }),
      copyReplacementBaseline: _copyReplacementMap,
      copyOriginalReplacementBaseline: (slots) {
        if (removed.isEmpty) return _copyReplacementMap(backing, slots);
        final original = _copyReplacementMap(backing, null);
        for (var i = 0; i < removed.length; i += 2) {
          original[removed[i] as K] = removed[i + 1] as V;
        }
        return slots == null ? original : _copyReplacementMap(original, slots);
      },
      // Some maps apply their removals only after the last predicate.
      bulkVersion: (length) => removed.isEmpty ? 0 : length - backing.length,
    );
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
    final map = _untrackedValue;
    if (ifAbsent == null && !map.containsKey(key)) {
      return map.update(key, update);
    }
    final old = _readValue(map, key);
    final slot = _canRewindSlot(map, key) && !identical(old, _unreadable)
        ? (key: key, value: old, present: old != null || map.containsKey(key))
        : null;
    final deferWrite = _deferCallbackWrite(map, slot);

    return _mutate(
      (map) => map.update(
        key,
        deferWrite
            ? (value) => _beforeCallbackWrite(map, update(value))
            : update,
        ifAbsent: deferWrite && ifAbsent != null
            ? () => _beforeCallbackWrite(map, ifAbsent())
            : ifAbsent,
      ),
      slotChanged: () => !identical(old, _readValue(map, key)),
      copyReplacementBaseline: equals ? _copyReplacementMap : null,
      replacementSlot: slot,
      deferReplacementWrite: deferWrite,
    );
  }

  bool _deferCallbackWrite(Map<K, V> map, _ReplacementSlot? slot) =>
      slot == null && _replacementBaseline != null && identical(map, _mutating);

  V _beforeCallbackWrite(Map<K, V> map, V next) {
    // A replacement made by the callback can commit before the backing
    // writes this slot. In that case, there is no outgoing map to copy.
    if (identical(map, _untrackedValue)) _rememberReplacementWrite(map, null);
    return next;
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
    if (!equals) {
      return _mutate(
        (map) => map.updateAll(update),
        bulkCheck: _bulkChangeCheck,
      );
    }

    final nested = identical(_untrackedValue, _mutating);
    late Map<K, V> Function() copyOriginal;
    var version = 0;
    var hasRead = false;
    _mutate(
      (map) => map.updateAll((key, value) {
        final next = update(key, value);
        if (!identical(value, next) &&
            (!hasRead || !_sameReplacementValue(value, next))) {
          version++;
        }
        return next;
      }),
      bulkCheck: nested
          ? _bulkChangeCheck
          : (map, previous) => _bulkChangeCheck(
              map,
              previous,
              saveOriginal: (copy) => copyOriginal = copy,
            ),
      copyReplacementBaseline: _copyReplacementMap,
      copyOriginalReplacementBaseline: (_) => copyOriginal(),
      bulkVersion: (_) {
        hasRead = true;
        return version;
      },
    );
  }

  bool _sameReplacementValue(V before, V after) {
    try {
      return untracked(() => before == after);
    } on Object {
      // Comparing an intermediate value must not interrupt the backing write.
      return false;
    }
  }

  @override
  String toString() =>
      '''MapSignal<$K, $V>(value: $_value, previousValue: $_previousValue)''';

  // A cast view can reject a read even when the backing write is valid.
  static final _unreadable = Object();

  Object? _readValue(Map<K, V> map, Object? key) {
    try {
      return map[key];
    } on Object {
      return _unreadable;
    }
  }

  /// The keys that [list] returns, or null if listing them throws. Then the
  /// backing call meets the same error after its own partial writes.
  List<K>? _keysOf(List<K> Function() list) {
    try {
      return list();
    } on Object {
      return null;
    }
  }

  /// Runs [write], which can change only the values of [keys]. Without
  /// [keys], compares the whole map.
  R _writeKeys<R>(List<K>? keys, R Function(Map<K, V>) write) {
    if (keys == null) return _mutate(write, bulkCheck: _bulkChangeCheck);
    final map = _untrackedValue;
    final before = List<Object?>.filled(keys.length, null);
    for (var i = 0; i < keys.length; i++) {
      before[i] = _readValue(map, keys[i]);
    }
    return _mutate(
      write,
      slotChanged: () {
        for (var i = 0; i < keys.length; i++) {
          if (!identical(before[i], _readValue(map, keys[i]))) return true;
        }
        return false;
      },
    );
  }

  @override
  int _lengthOf(Map<K, V> map) => map.length;

  @override
  Map<K, V> _copyPrevious(Map<K, V> map) => Map<K, V>.of(map);

  _ReplacementSlot _readReplacementSlot(Map<K, V> map, Object? key) {
    final value = map[key];
    return (
      key: key,
      value: value,
      present: value != null || map.containsKey(key),
    );
  }

  bool _replacementSlotsMatch(
    Map<K, V> map,
    Iterable<_ReplacementSlot> slots,
  ) {
    for (final slot in slots) {
      final present = map.containsKey(slot.key);
      if (present != slot.present || (present && slot.value != map[slot.key])) {
        return false;
      }
    }
    return true;
  }

  Map<K, V> _copyReplacementMap(
    Map<K, V> map,
    Map<Object?, _ReplacementSlot>? slots,
  ) {
    // An identity copy preserves distinct equal keys in custom backings.
    final copy = Map<K, V>.identity();
    if (slots == null) return copy..addAll(map);
    map.forEach((key, value) {
      final original = _isValueKey(key) ? slots.remove(key) : null;
      if (original == null) {
        copy[key] = value;
      } else if (original.present) {
        copy[key] = original.value as V;
      }
    });
    for (final original in slots.values) {
      if (original.present) copy[original.key as K] = original.value as V;
    }
    return copy;
  }

  bool Function() _bulkChangeCheck(
    Map<K, V> map,
    Map<K, V>? previous, {
    void Function(Map<K, V> Function())? saveOriginal,
  }) {
    if (previous != null && previous.length == map.length) {
      saveOriginal?.call(() => Map<K, V>.identity()..addAll(previous));
      return () {
        final keys = previous.keys.iterator;
        final values = previous.values.iterator;
        var changed = false;
        map.forEach((key, value) {
          keys.moveNext();
          values.moveNext();
          if (!identical(key, keys.current) ||
              !identical(value, values.current)) {
            changed = true;
          }
        });
        return changed;
      };
    }

    // A plain history map can merge distinct keys from an identity map.
    final before = List<Object?>.filled(2 * map.length, null);
    var i = 0;
    map.forEach((key, value) {
      before[i++] = key;
      before[i++] = value;
    });
    saveOriginal?.call(() {
      final snapshot = Map<K, V>.identity();
      for (var i = 0; i < before.length; i += 2) {
        snapshot[before[i] as K] = before[i + 1] as V;
      }
      return snapshot;
    });
    return () {
      var i = 0;
      var changed = false;
      map.forEach((key, value) {
        if (!identical(key, before[i]) || !identical(value, before[i + 1])) {
          changed = true;
        }
        i += 2;
      });
      return changed;
    };
  }

  @override
  // ignore: overridden_fields
  final _id = ReactiveName.nameFor('MapSignal');
}
