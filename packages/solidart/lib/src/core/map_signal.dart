part of '../solidart.dart';

/// {@template solidart.map-signal}
/// A reactive wrapper around a [Map] that copies on write.
///
/// Mutations create a new map instance so that updates are observable:
/// ```dart
/// final map = MapSignal({'a': 1});
/// Effect(() => print(map['a']));
/// map['a'] = 2; // triggers effect
/// ```
///
/// Reads (like `[]`, `keys`, or `length`) establish dependencies.
/// {@endtemplate}
class MapSignal<K, V> extends Signal<Map<K, V>> with MapMixin<K, V> {
  /// {@macro solidart.map-signal}
  ///
  /// Creates a reactive map with the provided initial values.
  MapSignal(
    Map<K, V> initialValue, {
    bool? autoDispose,
    String? name,
    ValueComparator<Map<K, V>> equals = identical,
    bool? trackPreviousValue,
    bool? trackInDevTools,
  }) : super(
         Map<K, V>.of(initialValue),
         autoDispose: autoDispose,
         name: name,
         equals: equals,
         trackPreviousValue: trackPreviousValue,
         trackInDevTools: trackInDevTools,
       );

  @override
  bool get isEmpty {
    value;
    return untrackedValue.isEmpty;
  }

  @override
  bool get isNotEmpty {
    value;
    return untrackedValue.isNotEmpty;
  }

  @override
  Iterable<K> get keys {
    value;
    return untrackedValue.keys;
  }

  @override
  int get length {
    value;
    return untrackedValue.length;
  }

  @override
  V? operator [](Object? key) {
    value;
    return untrackedValue[key];
  }

  @override
  void operator []=(K key, V value) {
    final current = untrackedValue;
    final existing = current[key];
    if (current.containsKey(key) && existing == value) return;
    final next = _copy();
    next[key] = value;
    this.value = next;
  }

  @override
  void addAll(Map<K, V> other) {
    if (other.isEmpty) return;
    final current = untrackedValue;
    final next = _copy()..addAll(other);
    if (_mapEquals(next, current)) return;
    value = next;
  }

  @override
  Map<RK, RV> cast<RK, RV>() =>
      MapSignal<RK, RV>(untrackedValue.cast<RK, RV>());

  @override
  void clear() {
    if (untrackedValue.isEmpty) return;
    value = <K, V>{};
  }

  @override
  bool containsKey(Object? key) {
    value;
    return untrackedValue.containsKey(key);
  }

  @override
  bool containsValue(Object? value) {
    this.value;
    return untrackedValue.containsValue(value);
  }

  @override
  V putIfAbsent(K key, V Function() ifAbsent) {
    final current = untrackedValue;
    if (current.containsKey(key)) {
      return current[key] as V;
    }
    final next = _copy();
    final value = ifAbsent();
    next[key] = value;
    this.value = next;
    return value;
  }

  @override
  V? remove(Object? key) {
    final current = untrackedValue;
    if (!current.containsKey(key)) return null;
    final next = _copy();
    final removed = next.remove(key);
    value = next;
    return removed;
  }

  @override
  void removeWhere(bool Function(K key, V value) test) {
    final current = untrackedValue;
    if (current.isEmpty) return;
    final next = _copy()..removeWhere(test);
    if (next.length == current.length) return;
    value = next;
  }

  @override
  String toString() =>
      'MapSignal<$K, $V>(value: $untrackedValue, '
      'previousValue: $untrackedPreviousValue)';

  @override
  V update(
    K key,
    V Function(V value) update, {
    V Function()? ifAbsent,
  }) {
    final current = untrackedValue;
    if (!current.containsKey(key)) {
      if (ifAbsent == null) {
        throw ArgumentError.value(key, 'key', 'Key not in map.');
      }
      final next = _copy();
      final value = ifAbsent();
      next[key] = value;
      this.value = next;
      return value;
    }

    final next = _copy();
    final value = update(next[key] as V);
    next[key] = value;
    this.value = next;
    return value;
  }

  @override
  void updateAll(V Function(K key, V value) update) {
    final current = untrackedValue;
    if (current.isEmpty) return;
    final next = _copy()..updateAll(update);
    if (next.length == current.length &&
        next.keys.every((key) {
          return current.containsKey(key) && current[key] == next[key];
        })) {
      return;
    }
    value = next;
  }

  Map<K, V> _copy() => Map<K, V>.of(untrackedValue);

  bool _mapEquals(Map<K, V> a, Map<K, V> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (!b.containsKey(entry.key)) return false;
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}
