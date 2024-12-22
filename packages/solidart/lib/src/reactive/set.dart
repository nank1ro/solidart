import 'dart:collection';

import 'package:alien_signals/alien_signals.dart' hide Signal;
import 'package:solidart/src/api_untrack.dart';
import 'package:solidart/src/namespace.dart';
import 'package:solidart/src/signal.dart';

// ignore: public_member_api_docs
class SetSignal<E> extends SetBase<E> implements Signal<Set<E>> {
  // ignore: public_member_api_docs
  SetSignal(
    Iterable<E> initialValue, {
    String? name,
    bool Function(Object? a, Object? b)? comparator,
    bool? equals,
  }) : _inner = Signal(
          Set.from(initialValue),
          name: name ?? 'SetSignal<$E>',
          equals: equals ?? Solidart.equals,
          comparator: comparator ?? identical,
        );

  final Signal<Set<E>> _inner;

  @override
  Set<E> get value => _inner.value;

  @override
  set value(Set<E> value) {
    _inner.value = value;
  }

  @override
  bool Function(Object? a, Object? b) get comparator => _inner.comparator;

  @override
  bool get equals => _inner.equals;

  @override
  String get name => _inner.name;

  @override
  bool add(E value) {
    final result = untrack(this).add(value);
    if (result) {
      final subs = (_inner as Dependency).subs;
      if (subs != null) {
        propagate(subs);
      }
    }

    return result;
  }

  @override
  bool contains(Object? element) {
    return value.contains(element);
  }

  @override
  Iterator<E> get iterator => value.iterator;

  @override
  int get length => value.length;

  @override
  E? lookup(Object? element) {
    return value.lookup(element);
  }

  @override
  bool remove(Object? value) {
    if (untrack(this).remove(value)) {
      final subs = (_inner as Dependency).subs;
      if (subs != null) {
        propagate(subs);
      }

      return true;
    }

    return false;
  }

  @override
  Set<E> toSet() {
    return value.toSet();
  }
}
