import 'dart:collection';

import 'package:alien_signals/alien_signals.dart' hide Signal;
import 'package:solidart/src/api_untrack.dart';
import 'package:solidart/src/namespace.dart';
import 'package:solidart/src/signal.dart';

// ignore: public_member_api_docs
class ListSignal<E> extends ListBase<E> implements Signal<List<E>>, List<E> {
  // ignore: public_member_api_docs
  ListSignal(
    Iterable<E> initialValue, {
    String? name,
    bool Function(Object? a, Object? b)? comparator,
    bool? equals,
  }) : _inner = Signal(
          List.from(initialValue),
          name: name ?? 'ListSignal<$E>',
          equals: equals ?? Solidart.equals,
          comparator: comparator ?? identical,
        );

  final Signal<List<E>> _inner;

  @override
  List<E> get value => _inner.value;

  @override
  set value(List<E> value) => _inner.value = value;

  @override
  bool Function(Object? a, Object? b) get comparator => _inner.comparator;

  @override
  bool get equals => _inner.equals;

  @override
  String get name => _inner.name;

  @override
  int get length => value.length;

  @override
  set length(int value) {
    final untracked = untrack(this);
    final oldValue = untracked.length;
    // ignore: inference_failure_on_untyped_parameter
    final eq = equals ? comparator : (a, b) => a == b;
    if (!eq(oldValue, value)) {
      untracked.length = value;
      final dep = _inner as Dependency;
      if (dep.subs != null) {
        propagate(dep.subs);
      }
    }
  }

  @override
  E operator [](int index) {
    return value[index];
  }

  @override
  void operator []=(int index, E value) {
    final untracked = untrack(this);
    final oldValue = untracked[index];
    // ignore: inference_failure_on_untyped_parameter
    final eq = equals ? comparator : (a, b) => a == b;
    if (!eq(oldValue, value)) {
      untracked[index] = value;
      final dep = _inner as Dependency;
      if (dep.subs != null) {
        propagate(dep.subs);
      }
    }
  }
}
