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
      if (identical(oldValue, newValue)) return true;
      if (oldValue is LinkedHashMap<K, V> &&
          newValue is LinkedHashMap<K, V> &&
          oldValue.runtimeType == _defaultMapType &&
          newValue.runtimeType == _defaultMapType &&
          oldValue.length == newValue.length &&
          _orderedEntriesMatch(oldValue, newValue)) {
        return true;
      }
      return MapEquality<K, V>().equals(oldValue, newValue);
    }

    // return the [comparator] result
    return comparator(oldValue, newValue);
  }

  // Match ordinary entries without hashing. Differently ordered maps and
  // entries with user-defined equality still use MapEquality.
  bool _orderedEntriesMatch(Map<K, V> oldValue, Map<K, V> newValue) {
    final oldKeys = oldValue.keys.iterator;
    final newKeys = newValue.keys.iterator;
    final oldValues = oldValue.values.iterator;
    final newValues = newValue.values.iterator;
    while (oldKeys.moveNext()) {
      newKeys.moveNext();
      oldValues.moveNext();
      newValues.moveNext();
      if (!_samePrimitiveValue(oldKeys.current, newKeys.current) ||
          !_samePrimitiveValue(oldValues.current, newValues.current)) {
        return false;
      }
    }
    return true;
  }

  bool _samePrimitiveValue(Object? oldValue, Object? newValue) =>
      _isValueKey(oldValue) && _isValueKey(newValue) && oldValue == newValue;

  @override
  Map<K, V> get _value {
    final baseline = _replacementBaseline;
    final previousTail = baseline == null ? null : _internalSignal.subsTail;
    final value = super._value;
    final observer = baseline == null ? null : reactiveSystem.activeSub;
    if (baseline != null &&
        observer != null &&
        identical(value, _mutating) &&
        !disposed) {
      final tail = _internalSignal.subsTail;
      final newSubscription =
          previousTail != null &&
              tail != null &&
              identical(tail.prevSub, previousTail) &&
              identical(tail.sub, observer)
          ? tail
          : null;
      baseline.recordRead(
        _internalSignal,
        value,
        _compare,
        _replacementSlotsMatch,
        _readReplacementSlot,
        firstObserver: previousTail == null,
        observer: observer,
        newSubscription: newSubscription,
      );
    }
    return value;
  }

  @override
  void _setValueAndNotify(Map<K, V> newValue) {
    if (_mutating case final map?) {
      // Two distinct default maps have separate storage. A view can share
      // storage with any map a callback is still mutating.
      _mutatingOpaqueMap |= map.runtimeType != _defaultMapType;
      _mutationReplacement =
          _mutatingOpaqueMap || newValue.runtimeType != _defaultMapType
          ? _snapshotReplacement(newValue)
          : null;
    }
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
        final comparison = baseline.replacementComparison(
          snapshot,
          signal,
          _compare,
        );
        if (signal.forceDirty || !identical(signal.currentValue, committed)) {
          return;
        }
        if (comparison.notify) {
          // A subscriber read an intermediate change, or a nested write
          // changed a map whose original state could not be copied.
          signal.forceDirty = true;
        } else if (comparison.snapshot case final observed?) {
          signal.currentValue = Some(observed);
        }
      }
    });
  }

  // An outer view can still write to a default map after a nested assignment.
  bool _mutatingOpaqueMap = false;
  ({Map<K, V> map, Object before})? _mutationReplacement;

  ({Map<K, V> map, Object before})? _snapshotReplacement(Map<K, V> map) {
    try {
      final before = untracked(() => _copyReplacementMap(map, null));
      return (map: map, before: before);
    } on Object {
      // A cast view can enumerate keys even when a value cannot be read.
      try {
        final before = untracked(
          () => [
            for (final key in map.keys) (key: key, value: _readValue(map, key)),
          ],
        );
        return (map: map, before: before);
      } on Object {
        return null;
      }
    }
  }

  @override
  ({Map<K, V>? previous})? _changedReplacement(Map<K, V> collection) {
    final replacement = _mutationReplacement;
    if (_mutating == null) {
      _mutationReplacement = null;
      _mutatingOpaqueMap = false;
    }
    if (replacement == null ||
        identical(replacement.map, collection) ||
        !identical(replacement.map, _untrackedValue)) {
      return null;
    }
    final before = replacement.before;
    try {
      final changed = untracked(() {
        final map = replacement.map;
        if (before is Map<K, V>) {
          return before.length != map.length ||
              _replacementEntriesChanged(map, before);
        }
        final entries = before as List<({K key, Object? value})>;
        if (entries.length != map.length) return true;
        var i = 0;
        for (final key in map.keys) {
          final entry = entries[i++];
          if (!identical(entry.key, key) ||
              !identical(entry.value, _readValue(map, key))) {
            return true;
          }
        }
        return i != entries.length;
      });
      if (!changed || !identical(replacement.map, _untrackedValue)) return null;
    } on Object {
      return null;
    }
    if (before is! Map<K, V>) return (previous: null);
    var previous = before;
    if (trackPreviousValue) {
      try {
        previous = untracked(() => _copyPrevious(before));
      } on Object {
        // The identity copy still holds history for keys that throw on hash.
      }
    }
    return identical(replacement.map, _untrackedValue)
        ? (previous: previous)
        : null;
  }

  @override
  void _reportChanged() {
    final replacement = _mutationReplacement;
    if (replacement != null && identical(replacement.map, _untrackedValue)) {
      // A nested write can publish the replacement while the original map
      // is still being mutated.
      final snapshot = _snapshotReplacement(replacement.map);
      if (identical(_mutationReplacement?.before, replacement.before)) {
        _mutationReplacement = snapshot;
      }
    }
    super._reportChanged();
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
  late final bool _hasValueKeys = _hasValueKeyType<K>();
  late final Type _unmodifiableMapType = Map<K, V>.unmodifiable({}).runtimeType;

  bool _hasNativeUnmodifiableType(Map<K, V> map) {
    final type = _unmodifiableMapType;
    return (type != UnmodifiableMapView<K, V>) && map.runtimeType == type;
  }

  bool _hasStableSlot(Map<K, V> map, K key) =>
      map.runtimeType == _defaultMapType && _isValueKey(key);

  bool _canRewindSlot(Map<K, V> map, K key) =>
      _replacementBaseline != null &&
      identical(_mutating, map) &&
      !_internalSignal.forceDirty &&
      _hasStableSlot(map, key);

  /// Associates the [key] with the given [value].
  ///
  /// If the key was already in the map, its associated value is changed.
  /// Otherwise the key/value pair is added to the map.
  @override
  void operator []=(K key, V value) =>
      _assignSlot(key, value, checkEquality: true);

  void _assignSlot(K key, V value, {required bool checkEquality}) {
    final map = _untrackedValue;
    var written = false;
    void write(Map<K, V> map) {
      map[key] = value;
      written = true;
    }

    if (map is UnmodifiableMapView<K, V> &&
        map.runtimeType == UnmodifiableMapView<K, V>) {
      return write(map);
    }
    final old = trackPreviousValue ? map[key] : _readValue(map, key);
    if (identical(old, _unreadable)) {
      // A cast or custom map can reject the lookup but accept the write.
      return _mutate(
        write,
        slotChanged: () => written || !identical(old, _readValue(map, key)),
      );
    }
    final defaultMap =
        map is LinkedHashMap<K, V> && map.runtimeType == _defaultMapType;
    final lazyMap = trackPreviousValue && defaultMap;
    final rewindable = _canRewindSlot(map, key);
    final sameValue = identical(old, value);
    final present =
        old != null ||
        ((lazyMap || sameValue || rewindable) && map.containsKey(key));
    final checkEquivalent =
        checkEquality &&
        !sameValue &&
        present &&
        _replacementBaseline != null &&
        identical(_mutating, map);
    var equivalent = false;
    if (checkEquivalent) {
      final comparison = _compareReplacementValue(old, value);
      if (comparison.changed) {
        // Equality can change the slot or replace the backing before the write.
        _assignSlot(key, value, checkEquality: false);
        return;
      }
      equivalent = comparison.equivalent;
    }
    // An overwrite keeps the caller's key in the undo step. The caller can
    // change a mutable key later, so only an immutable value key is lazy.
    // A new key is stored as it is, so only NaN cannot be undone.
    final lazy = lazyMap && (present ? _isValueKey(key) : !_isNaN(key));
    _mutateUnless(
      sameValue && present,
      write,
      // After a successful native write, the requested value is stored.
      slotChanged: () => (defaultMap && written) || !identical(old, map[key]),
      replacementSlot: rewindable
          ? (key: key, value: old, present: present)
          : null,
      equivalentReplacementWrite: equivalent,
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

  /// Applies [action] to each key/value pair in the map.
  @override
  void forEach(void Function(K key, V value) action) => _value.forEach(action);

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
    if (!trackPreviousValue && _replacementBaseline == null) {
      return _mutate((map) => map.remove(key));
    }
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
    final backing = _untrackedValue;
    // These SDK map types expose their length and keys without running
    // source callbacks. A view can run code or yield different keys on replay.
    final nativeInput =
        other is LinkedHashMap<K, V> ||
        other is HashMap<K, V> ||
        other is SplayTreeMap<K, V> ||
        _hasNativeUnmodifiableType(other);
    final inputLength = nativeInput ? other.length : null;
    if (inputLength == 0) return backing.addAll(other);

    // Forward the original map so the backing can use its fast copy.
    void write(Map<K, V> map) => map.addAll(other);
    final length = backing.length;
    if (length == 0) return _mutate(write, backing: backing);
    // Built-in key equality keeps the preflight lookup free of callbacks.
    if (trackPreviousValue &&
        inputLength == 1 &&
        backing.runtimeType == _defaultMapType &&
        other.runtimeType == _defaultMapType &&
        _hasValueKeys) {
      final MapEntry(:key, :value) = other.entries.first;
      if (identical(backing[key], value) &&
          (value != null || backing.containsKey(key))) {
        return write(backing);
      }
    }
    if (inputLength != null && inputLength <= length) {
      return _writeKeys(backing, other.keys.toList(growable: false), write);
    }
    _mutate(
      write,
      backing: backing,
      bulkCheck: (map, previous) =>
          _bulkChangeCheck(map, previous, allowWiderTypes: true),
      copyPrevious: _copyAddAllPrevious,
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
    final deferWrite = _deferCallbackWrite(map);
    final rewindable = deferWrite && _canRewindSlot(map, key);
    return _mutate(
      (map) => map.putIfAbsent(
        key,
        deferWrite
            ? () => _beforeCallbackWrite(map, key, ifAbsent(), rewindable)
            : ifAbsent,
      ),
      copyReplacementBaseline: equals ? _copyReplacementMap : null,
      bulkVersion: _pointCallbackVersion(map),
      deferReplacementWrite: deferWrite,
      keepBulkVersion: deferWrite,
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
      var accepted = false;
      return _mutate(
        (map) => map.removeWhere((key, value) {
          final remove = test(key, value);
          if (remove && !accepted && identical(map, _untrackedValue)) {
            accepted = true;
            _rememberReplacementWrite(map, null);
          }
          return remove;
        }),
        bulkVersion: (length) => length - backing.length,
        deferReplacementWrite: true,
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
    final deferWrite = _deferCallbackWrite(map);
    final rewindable = deferWrite && _canRewindSlot(map, key);
    var calledIfAbsent = false;

    return _mutate(
      (map) => map.update(
        key,
        deferWrite
            ? (value) =>
                  _beforeCallbackWrite(map, key, update(value), rewindable)
            : update,
        ifAbsent: ifAbsent == null
            ? null
            : () {
                calledIfAbsent = true;
                final next = ifAbsent();
                return deferWrite
                    ? _beforeCallbackWrite(map, key, next, rewindable)
                    : next;
              },
      ),
      slotChanged: () =>
          !identical(old, _readValue(map, key)) ||
          (calledIfAbsent && map.containsKey(key)),
      copyReplacementBaseline: equals ? _copyReplacementMap : null,
      bulkVersion: _pointCallbackVersion(map),
      deferReplacementWrite: deferWrite,
      keepBulkVersion: deferWrite,
    );
  }

  bool _deferCallbackWrite(Map<K, V> map) =>
      _replacementBaseline != null && identical(map, _mutating);

  // A point callback returns before the backing writes its slot.
  // Nested writes that can change the comparison invalidate it separately.
  int Function(int)? _pointCallbackVersion(Map<K, V> map) =>
      equals && !identical(map, _mutating) ? (_) => 0 : null;

  V _beforeCallbackWrite(Map<K, V> map, K key, V next, bool rewindable) {
    // The callback may already have replaced the backing map.
    if (!identical(map, _untrackedValue)) return next;
    var previous = _readSlotForWrite(map, key);
    var equivalent = false;
    if (previous != null &&
        previous.present &&
        !identical(previous.value, next)) {
      final comparison = _compareReplacementValue(previous.value, next);
      if (comparison.changed) {
        if (!identical(map, _untrackedValue)) return next;
        previous = _readSlotForWrite(map, key);
      }
      equivalent = comparison.equivalent;
    }
    if (previous == null ||
        !previous.present ||
        !identical(previous.value, next)) {
      _rememberReplacementWrite(
        map,
        rewindable ? previous : null,
        equivalent: equivalent,
      );
    }
    return next;
  }

  _ReplacementSlot? _readSlotForWrite(Map<K, V> map, K key) {
    try {
      return untracked(() => _readReplacementSlot(map, key));
    } on Object {
      // An unreadable slot still needs the normal fallback before a write.
      return null;
    }
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
    var savedBaseline = false;
    _mutate(
      (map) => map.updateAll((key, value) {
        final baseline = _replacementBaseline;
        final writeVersion = baseline?.writeVersion;
        final next = update(key, value);
        if (!identical(map, _untrackedValue)) return next;
        // A nested write can overwrite this key before the callback returns.
        final before = writeVersion == baseline?.writeVersion
            ? value
            : untracked(() => _readValue(map, key));
        if (!identical(before, next)) {
          final equivalent = _compareReplacementValue(before, next).equivalent;
          if (nested && !savedBaseline) {
            _rememberReplacementWrite(map, null, equivalent: equivalent);
            savedBaseline = !equivalent;
          }
          if (!equivalent) version++;
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
      bulkVersion: (_) => version,
      deferReplacementWrite: true,
    );
  }

  ({bool equivalent, bool changed}) _compareReplacementValue(
    Object? before,
    V after,
  ) {
    final baseline = _replacementBaseline;
    final map = _untrackedValue;
    final writes = baseline?.writeVersion;
    var equal = false;
    try {
      equal = untracked(() => before == after);
    } on Object {
      // Comparing an intermediate value must not interrupt the backing write.
    }
    final changed =
        !identical(_replacementBaseline, baseline) ||
        !identical(_untrackedValue, map) ||
        baseline?.writeVersion != writes;
    return (equivalent: equal && !changed, changed: changed);
  }

  @override
  String toString() =>
      '''MapSignal<$K, $V>(value: $_value, previousValue: $_previousDescription)''';

  // A cast view can reject a read even when the backing write is valid.
  static final _unreadable = Object();

  Object? _readValue(Map<K, V> map, Object? key) {
    try {
      return map[key];
    } on Object {
      return _unreadable;
    }
  }

  /// Runs [write], which can change only the slots for [keys].
  R _writeKeys<R>(Map<K, V> map, List<K> keys, R Function(Map<K, V>) write) {
    final before = List<Object?>.filled(keys.length, null);
    for (var i = 0; i < keys.length; i++) {
      before[i] = _readValue(map, keys[i]);
    }
    return _mutate(
      write,
      backing: map,
      copyPrevious: _copyAddAllPrevious,
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

  late final Set<Type> _sdkCastMapTypes = _buildSdkCastMapTypes();

  Set<Type> _buildSdkCastMapTypes() {
    // Cast views reify both their source and destination types.
    const empty = <Never, Never>{};
    final types = <Type>{};
    void addSourceValues<SK>() {
      types
        ..add(Map.castFrom<SK, V, K, V>(empty).runtimeType)
        ..add(Map.castFrom<SK, V?, K, V>(empty).runtimeType)
        ..add(Map.castFrom<SK, Object, K, V>(empty).runtimeType)
        ..add(Map.castFrom<SK, Object?, K, V>(empty).runtimeType)
        ..add(Map.castFrom<SK, dynamic, K, V>(empty).runtimeType)
        ..add(Map.castFrom<SK, num, K, V>(empty).runtimeType)
        ..add(Map.castFrom<SK, num?, K, V>(empty).runtimeType);
    }

    addSourceValues<K>();
    addSourceValues<K?>();
    addSourceValues<Object>();
    addSourceValues<Object?>();
    addSourceValues<dynamic>();
    addSourceValues<num>();
    addSourceValues<num?>();
    return types;
  }

  Map<Object?, Object?>? _widerMapEntries(Map<K, V> map) {
    if (!_sdkCastMapTypes.contains(map.runtimeType)) return null;
    final wider = map.cast<Object?, Object?>();
    // A cast view can also propagate an unrelated error from its source.
    var unreadable = false;
    wider.forEach((key, value) {
      unreadable |= key is! K || value is! V;
    });
    return unreadable ? wider : null;
  }

  Map<K, V>? _copyAddAllPrevious(Map<K, V> map) {
    try {
      return _copyPrevious(map);
      // ignore: avoid_catching_errors
    } on TypeError catch (error, stack) {
      // A cast map can have entries that the public history type cannot hold.
      // Still run addAll so a no-op does not require a typed history copy.
      try {
        if (_widerMapEntries(map) != null) return null;
      } on Object {
        Error.throwWithStackTrace(error, stack);
      }
      rethrow;
    }
  }

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
    bool allowWiderTypes = false,
  }) {
    // For small maps, unwinding the callback costs more than a full scan.
    // Custom maps must finish forEach because they can throw after a change.
    final canStop =
        map is LinkedHashMap<K, V> &&
        map.length >= 512 &&
        map.runtimeType == _defaultMapType;

    bool Function() stopOnChange(bool Function() check) {
      if (!canStop) return check;
      return () {
        try {
          return check();
        } on _BulkMapChanged {
          return true;
        }
      };
    }

    Map<Object?, Object?>? widerEntries;
    T readEntries<T>(T Function(Map<Object?, Object?>) read) {
      if (!allowWiderTypes) return read(map);
      final wider = widerEntries;
      if (wider != null) return read(wider);
      try {
        return read(map);
        // ignore: avoid_catching_errors
      } on TypeError catch (error, stack) {
        // A wider cast can visit the original entries without per-key lookups.
        try {
          final entries = _widerMapEntries(map);
          if (entries != null) {
            final result = read(entries);
            widerEntries = entries;
            return result;
          }
        } on Object {
          Error.throwWithStackTrace(error, stack);
        }
        rethrow;
      }
    }

    if (previous != null && previous.length == map.length) {
      saveOriginal?.call(() => Map<K, V>.identity()..addAll(previous));
      return stopOnChange(
        () => readEntries((entries) {
          final keys = previous.keys.iterator;
          final values = previous.values.iterator;
          var changed = false;
          entries.forEach((key, value) {
            keys.moveNext();
            values.moveNext();
            if (!identical(key, keys.current) ||
                !identical(value, values.current)) {
              if (canStop) throw const _BulkMapChanged();
              changed = true;
            }
          });
          return changed;
        }),
      );
    }

    // A plain history map can merge distinct keys from an identity map.
    final before = List<Object?>.filled(2 * map.length, null);
    void capture(Map<Object?, Object?> entries) {
      var i = 0;
      entries.forEach((key, value) {
        before[i++] = key;
        before[i++] = value;
      });
    }

    readEntries(capture);
    saveOriginal?.call(() {
      final snapshot = Map<K, V>.identity();
      for (var i = 0; i < before.length; i += 2) {
        snapshot[before[i] as K] = before[i + 1] as V;
      }
      return snapshot;
    });
    return stopOnChange(
      () => readEntries((entries) {
        var i = 0;
        var changed = false;
        entries.forEach((key, value) {
          if (!identical(key, before[i]) || !identical(value, before[i + 1])) {
            if (canStop) throw const _BulkMapChanged();
            changed = true;
          }
          i += 2;
        });
        return changed;
      }),
    );
  }

  bool _replacementEntriesChanged(Map<K, V> map, Map<K, V> before) {
    final keys = before.keys.iterator;
    final values = before.values.iterator;
    var changed = false;
    map.forEach((key, value) {
      keys.moveNext();
      values.moveNext();
      if (!identical(key, keys.current) || !identical(value, values.current)) {
        changed = true;
      }
    });
    return changed;
  }

  @override
  // ignore: overridden_fields
  final _id = ReactiveName.nameFor('MapSignal');
}

class _BulkMapChanged implements Exception {
  const _BulkMapChanged();
}
