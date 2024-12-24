import 'dart:collection';

import 'package:alien_signals/alien_signals.dart' hide Signal;
import 'package:solidart/src/api_untrack.dart';
import 'package:solidart/src/namespace.dart';
import 'package:solidart/src/signal.dart';

// ignore: public_member_api_docs
class MapSignal<K, V>
    with MapBase<K, V>
    implements Signal<Map<K, V>>, Map<K, V> {
  // ignore: public_member_api_docs
  MapSignal(
    Map<K, V> initialValue, {
    String? name,
    bool Function(Object? a, Object? b)? comparator,
    bool? equals,
  }) : _inner = Signal(
          Map.from(initialValue),
          name: name ?? 'MapSignal<$K, $V>',
          equals: equals ?? Solidart.equals,
          comparator: comparator ?? identical,
        );

  final Signal<Map<K, V>> _inner;

  @override
  Map<K, V> get value => _inner.value;

  @override
  set value(Map<K, V> value) {
    _inner.value = value;
  }

  @override
  bool Function(Object? a, Object? b) get comparator => _inner.comparator;

  @override
  bool get equals => _inner.equals;

  @override
  String get name => _inner.name;

  @override
  V? operator [](Object? key) {
    return value[key];
  }

  @override
  void operator []=(K key, V value) {
    final untracked = untrack(() => _inner.value);
    final oldValue = untracked[key];
    // ignore: inference_failure_on_untyped_parameter
    final eq = equals ? comparator : (a, b) => a == b;
    if (!eq(oldValue, value)) {
      untracked[key] = value;
      final subs = (_inner as Dependency).subs;
      if (subs != null) {
        propagate(subs);
      }
    }
  }

  @override
  void clear() {
    final untracked = untrack(() => value);
    if (untracked.isEmpty) return;
    untracked.clear();
    final subs = (_inner as Dependency).subs;
    if (subs != null) {
      propagate(subs);
    }
  }

  @override
  Iterable<K> get keys => value.keys;

  @override
  V? remove(Object? key) {
    final untracked = untrack(() => value);
    final oldLenght = untracked.length;

    try {
      return untracked.remove(key);
    } finally {
      final newLength = untracked.length;
      if (oldLenght != newLength) {
        final subs = (_inner as Dependency).subs;
        if (subs != null) {
          propagate(subs);
        }
      }
    }
  }
}
