// ignore_for_file: public_member_api_docs
// TODO(medz): Add code comments

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:math';

import 'package:meta/meta.dart';
import 'package:solidart/deps/preset.dart' as preset;
import 'package:solidart/deps/system.dart' as system;

typedef ValueComparator<T> = bool Function(T? a, T? b);
typedef ValueGetter<T> = T Function();
typedef VoidCallback = ValueGetter<void>;

sealed class Option<T> {
  const Option();

  T unwrap() => switch (this) {
    Some<T>(:final value) => value,
    _ => throw StateError('Option is None'),
  };

  T? safeUnwrap() => switch (this) {
    Some<T>(:final value) => value,
    _ => null,
  };
}

final class Some<T> extends Option<T> {
  const Some(this.value);

  final T value;
}

final class None<T> extends Option<T> {
  const None();
}

final class SolidartConfig {
  const SolidartConfig._();

  static bool autoDispose = false;
  static bool detachEffects = false;
  static bool trackPreviousValue = true;
  static bool useRefreshing = true;
  static bool devToolsEnabled = false;

  static final observers = <SolidartObserver>[];
}

abstract class SolidartObserver {
  const SolidartObserver();

  void didCreateSignal(ReadonlySignal<Object?> signal);
  void didUpdateSignal(ReadonlySignal<Object?> signal);
  void didDisposeSignal(ReadonlySignal<Object?> signal);
}

void _notifySignalCreation(ReadonlySignal<Object?> signal) {
  if (signal.trackInDevTools && SolidartConfig.observers.isNotEmpty) {
    for (final observer in SolidartConfig.observers) {
      observer.didCreateSignal(signal);
    }
  }
  _notifyDevToolsAboutSignal(signal, eventType: _DevToolsEventType.created);
}

void _notifySignalUpdate(ReadonlySignal<Object?> signal) {
  if (signal.trackInDevTools && SolidartConfig.observers.isNotEmpty) {
    for (final observer in SolidartConfig.observers) {
      observer.didUpdateSignal(signal);
    }
  }
  _notifyDevToolsAboutSignal(signal, eventType: _DevToolsEventType.updated);
}

void _notifySignalDisposal(ReadonlySignal<Object?> signal) {
  if (signal.trackInDevTools && SolidartConfig.observers.isNotEmpty) {
    for (final observer in SolidartConfig.observers) {
      observer.didDisposeSignal(signal);
    }
  }
  _notifyDevToolsAboutSignal(signal, eventType: _DevToolsEventType.disposed);
}

enum _DevToolsEventType {
  created,
  updated,
  disposed,
}

dynamic _toJson(Object? obj) {
  try {
    return jsonEncode(obj);
  } catch (_) {
    if (obj is List) {
      return obj.map(_toJson).toList().toString();
    }
    if (obj is Set) {
      return obj.map(_toJson).toList().toString();
    }
    if (obj is Map) {
      return obj
          .map((key, value) => MapEntry(_toJson(key), _toJson(value)))
          .toString();
    }
    return jsonEncode(obj.toString());
  }
}

void _notifyDevToolsAboutSignal(
  ReadonlySignal<Object?> signal, {
  required _DevToolsEventType eventType,
}) {
  if (!SolidartConfig.devToolsEnabled || !signal.trackInDevTools) return;
  final eventName = 'ext.solidart.v3.signal.${eventType.name}';
  final value = _signalValue(signal);
  final previousValue = _signalPreviousValue(signal);
  final hasPreviousValue = _hasPreviousValue(signal);

  dev.postEvent(eventName, {
    '_id': signal.identifier.value.toString(),
    'name': signal.identifier.name,
    'value': _toJson(value),
    'previousValue': _toJson(previousValue),
    'hasPreviousValue': hasPreviousValue,
    'type': _signalType(signal),
    'valueType': value.runtimeType.toString(),
    if (hasPreviousValue)
      'previousValueType': previousValue.runtimeType.toString(),
    'disposed': signal.isDisposed,
    'autoDispose': signal.autoDispose,
    'listenerCount': _listenerCount(signal),
    'lastUpdate': DateTime.now().toIso8601String(),
  });
}

String _signalType(ReadonlySignal<Object?> signal) => switch (signal) {
  Resource() => 'Resource',
  ReactiveList() => 'ReactiveList',
  ReactiveMap() => 'ReactiveMap',
  ReactiveSet() => 'ReactiveSet',
  LazySignal() => 'LazySignal',
  Signal() => 'Signal',
  Computed() => 'Computed',
  _ => 'ReadonlySignal',
};

int _listenerCount(system.ReactiveNode node) {
  var count = 0;
  var link = node.subs;
  while (link != null) {
    count++;
    link = link.nextSub;
  }
  return count;
}

bool _hasPreviousValue(ReadonlySignal<Object?> signal) {
  if (!signal.trackPreviousValue) return false;
  if (signal is Signal) {
    return signal._previousValue is Some;
  }
  if (signal is Computed) {
    return signal._previousValue is Some;
  }
  return false;
}

Object? _signalValue(ReadonlySignal<Object?> signal) {
  if (signal is Resource) {
    return _resourceValue(signal.untrackedState);
  }
  if (signal is LazySignal && !signal.isInitialized) {
    return null;
  }
  if (signal is Computed) {
    return _computedValue(signal);
  }
  return signal.untrackedValue;
}

Object? _signalPreviousValue(ReadonlySignal<Object?> signal) {
  if (signal is Resource) {
    return _resourceValue(signal.untrackedPreviousState);
  }
  return signal.untrackedPreviousValue;
}

Object? _resourceValue(ResourceState<dynamic>? state) {
  if (state == null) return null;
  return state.maybeWhen(orElse: () => null, ready: (value) => value);
}

Object? _computedValue<T>(Computed<T> signal) {
  final current = signal.currentValue;
  if (current != null || null is T) {
    return current;
  }
  return null;
}

T untracked<T>(T Function() callback) {
  final prevSub = preset.setActiveSub();
  try {
    return callback();
  } finally {
    preset.setActiveSub(prevSub);
  }
}

T batch<T>(T Function() fn) {
  preset.startBatch();
  try {
    return fn();
  } finally {
    preset.endBatch();
  }
}

class Identifier {
  Identifier._(this.name) : value = _counter++;
  static int _counter = 0;

  final String? name;
  final int value;
}

abstract interface class Configuration {
  Identifier get identifier;
  bool get autoDispose;
}

abstract class Disposable {
  bool get isDisposed;

  void onDispose(VoidCallback callback);
  void dispose();

  static bool canAutoDispose(system.ReactiveNode node) => switch (node) {
    Disposable(:final isDisposed) && Configuration(:final autoDispose) =>
      !isDisposed && autoDispose,
    _ => false,
  };

  static void unlinkDeps(system.ReactiveNode node) {
    var link = node.deps;
    while (link != null) {
      final next = link.nextDep;
      final dep = link.dep;
      preset.unlink(link, node);
      if (canAutoDispose(dep) && dep.subs == null) {
        (dep as Disposable).dispose();
      }
      link = next;
    }
  }

  static void unlinkSubs(system.ReactiveNode node) {
    var link = node.subs;
    while (link != null) {
      final next = link.nextSub;
      final sub = link.sub;
      preset.unlink(link, sub);
      if (canAutoDispose(sub) && sub.deps == null) {
        (sub as Disposable).dispose();
      }
      link = next;
    }
  }
}

abstract interface class SignalConfiguration<T> implements Configuration {
  ValueComparator<T> get equals;
  bool get trackPreviousValue;
  bool get trackInDevTools;
}

// TODO(nank1ro): Maybe rename to `ReadSignal`? medz: I still recommend `ReadonlySignal` because it is semantically clearer., https://github.com/nank1ro/solidart/pull/166#issuecomment-3623175977
abstract interface class ReadonlySignal<T>
    implements system.ReactiveNode, Disposable, SignalConfiguration<T> {
  T get value;
  T get untrackedValue;
  T? get previousValue;
  T? get untrackedPreviousValue;
}

class Signal<T> extends preset.SignalNode<Option<T>>
    with DisposableMixin
    implements ReadonlySignal<T> {
  Signal(
    T initialValue, {
    bool? autoDispose,
    String? name,
    ValueComparator<T> equals = identical,
    bool? trackPreviousValue,
    bool? trackInDevTools,
  }) : this._internal(
         Some(initialValue),
         autoDispose: autoDispose,
         name: name,
         equals: equals,
         trackPreviousValue: trackPreviousValue,
         trackInDevTools: trackInDevTools,
       );

  Signal._internal(
    Option<T> initialValue, {
    this.equals = identical,
    String? name,
    bool? autoDispose,
    bool? trackPreviousValue,
    bool? trackInDevTools,
  }) : autoDispose = autoDispose ?? SolidartConfig.autoDispose,
       trackPreviousValue =
           trackPreviousValue ?? SolidartConfig.trackPreviousValue,
       trackInDevTools = trackInDevTools ?? SolidartConfig.devToolsEnabled,
       identifier = ._(name),
       super(
         flags: system.ReactiveFlags.mutable,
         currentValue: initialValue,
         pendingValue: initialValue,
       ) {
    _notifySignalCreation(this);
  }

  factory Signal.lazy({
    String? name,
    bool? autoDispose,
    ValueComparator<T> equals,
    bool? trackPreviousValue,
    bool? trackInDevTools,
  }) = LazySignal;

  @override
  final bool autoDispose;

  @override
  final Identifier identifier;

  @override
  final ValueComparator<T> equals;

  @override
  final bool trackPreviousValue;

  @override
  final bool trackInDevTools;

  Option<T> _previousValue = const None();

  @override
  T get value {
    assert(!isDisposed, 'Signal is disposed');
    return super.get().unwrap();
  }

  set value(T newValue) {
    assert(!isDisposed, 'Signal is disposed');
    set(Some(newValue));
  }

  @override
  T get untrackedValue => super.currentValue.unwrap();

  @override
  T? get previousValue {
    if (!trackPreviousValue) return null;
    value;
    return _previousValue.safeUnwrap();
  }

  @override
  T? get untrackedPreviousValue {
    if (!trackPreviousValue) return null;
    return _previousValue.safeUnwrap();
  }

  // TODO(nank1ro): See ReadonlySignal TODO, If `ReadonlySignal` rename
  // to `ReadSignal`, the `.toReadonly` method should be rename?
  ReadonlySignal<T> toReadonly() => this;

  @override
  void dispose() {
    if (isDisposed) return;
    Disposable.unlinkSubs(this);
    preset.stop(this);
    super.dispose();
    _notifySignalDisposal(this);
  }

  @override
  bool didUpdate() {
    flags = system.ReactiveFlags.mutable;
    final current = currentValue;
    final pending = pendingValue;
    if (current is Some<T> &&
        pending is Some<T> &&
        equals(pending.value, current.value)) {
      return false;
    }

    if (trackPreviousValue && current is Some<T>) {
      _previousValue = current;
    }

    currentValue = pending;
    _notifySignalUpdate(this);
    return true;
  }
}

class LazySignal<T> extends Signal<T> {
  LazySignal({
    String? name,
    bool? autoDispose,
    ValueComparator<T> equals = identical,
    bool? trackPreviousValue,
    bool? trackInDevTools,
  }) : super._internal(
         const None(),
         name: name,
         autoDispose: autoDispose,
         equals: equals,
         trackPreviousValue: trackPreviousValue,
         trackInDevTools: trackInDevTools,
       );

  bool get isInitialized => currentValue is Some<T>;

  @override
  T get value {
    if (isInitialized) return super.value;
    throw StateError(
      'LazySignal is not initialized, Please call `.value = <newValue>` first.',
    );
  }

  @override
  bool didUpdate() {
    if (!isInitialized) {
      flags = system.ReactiveFlags.mutable;
      currentValue = pendingValue;
      return true;
    }

    return super.didUpdate();
  }
}

class ReactiveList<E> extends Signal<List<E>> with ListMixin<E> {
  ReactiveList(
    Iterable<E> initialValue, {
    bool? autoDispose,
    String? name,
    ValueComparator<List<E>> equals = identical,
    bool? trackPreviousValue,
    bool? trackInDevTools,
  }) : super(
         List<E>.of(initialValue),
         autoDispose: autoDispose,
         name: name,
         equals: equals,
         trackPreviousValue: trackPreviousValue,
         trackInDevTools: trackInDevTools,
       );

  List<E> _copy() => List<E>.of(untrackedValue);

  bool _listEquals(List<E> a, List<E> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get length => value.length;

  @override
  set length(int newLength) {
    final current = untrackedValue;
    if (current.length == newLength) return;
    final next = List<E>.of(current);
    next.length = newLength;
    value = next;
  }

  @override
  E operator [](int index) => value[index];

  @override
  void operator []=(int index, E element) {
    final current = untrackedValue;
    if (current[index] == element) return;
    final next = List<E>.of(current);
    next[index] = element;
    value = next;
  }

  @override
  void add(E element) {
    final next = _copy()..add(element);
    value = next;
  }

  @override
  void addAll(Iterable<E> iterable) {
    if (iterable.isEmpty) return;
    final next = _copy()..addAll(iterable);
    value = next;
  }

  @override
  void insert(int index, E element) {
    final next = _copy()..insert(index, element);
    value = next;
  }

  @override
  void insertAll(int index, Iterable<E> iterable) {
    if (iterable.isEmpty) return;
    final next = _copy()..insertAll(index, iterable);
    value = next;
  }

  @override
  bool remove(Object? element) {
    final current = untrackedValue;
    final index = current.indexWhere((value) => value == element);
    if (index == -1) return false;
    final next = List<E>.of(current)..removeAt(index);
    value = next;
    return true;
  }

  @override
  E removeAt(int index) {
    final current = untrackedValue;
    final removed = current[index];
    final next = List<E>.of(current)..removeAt(index);
    value = next;
    return removed;
  }

  @override
  E removeLast() {
    final current = untrackedValue;
    final removed = current.last;
    final next = List<E>.of(current)..removeLast();
    value = next;
    return removed;
  }

  @override
  void removeRange(int start, int end) {
    if (end <= start) return;
    final next = _copy()..removeRange(start, end);
    value = next;
  }

  @override
  void replaceRange(int start, int end, Iterable<E> replacements) {
    final next = _copy()..replaceRange(start, end, replacements);
    if (_listEquals(untrackedValue, next)) return;
    value = next;
  }

  @override
  void setAll(int index, Iterable<E> iterable) {
    final next = _copy()..setAll(index, iterable);
    if (_listEquals(untrackedValue, next)) return;
    value = next;
  }

  @override
  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    final next = _copy()..setRange(start, end, iterable, skipCount);
    if (_listEquals(untrackedValue, next)) return;
    value = next;
  }

  @override
  void fillRange(int start, int end, [E? fillValue]) {
    if (end <= start) return;
    final next = _copy()..fillRange(start, end, fillValue);
    if (_listEquals(untrackedValue, next)) return;
    value = next;
  }

  @override
  void clear() {
    if (untrackedValue.isEmpty) return;
    value = <E>[];
  }

  @override
  void sort([int Function(E a, E b)? compare]) {
    if (untrackedValue.length < 2) return;
    final next = _copy()..sort(compare);
    if (_listEquals(untrackedValue, next)) return;
    value = next;
  }

  @override
  void shuffle([Random? random]) {
    if (untrackedValue.length < 2) return;
    final next = _copy()..shuffle(random);
    if (_listEquals(untrackedValue, next)) return;
    value = next;
  }

  @override
  void removeWhere(bool Function(E element) test) {
    final current = untrackedValue;
    final next = List<E>.of(current)..removeWhere(test);
    if (next.length == current.length) return;
    value = next;
  }

  @override
  void retainWhere(bool Function(E element) test) {
    final current = untrackedValue;
    final next = List<E>.of(current)..retainWhere(test);
    if (next.length == current.length) return;
    value = next;
  }

  @override
  List<R> cast<R>() => ReactiveList<R>(untrackedValue.cast<R>());

  @override
  String toString() =>
      'ReactiveList<$E>(value: ${untrackedValue}, previousValue: ${untrackedPreviousValue})';
}

class ReactiveSet<E> extends Signal<Set<E>> with SetMixin<E> {
  ReactiveSet(
    Iterable<E> initialValue, {
    bool? autoDispose,
    String? name,
    ValueComparator<Set<E>> equals = identical,
    bool? trackPreviousValue,
    bool? trackInDevTools,
  }) : super(
         Set<E>.of(initialValue),
         autoDispose: autoDispose,
         name: name,
         equals: equals,
         trackPreviousValue: trackPreviousValue,
         trackInDevTools: trackInDevTools,
       );

  Set<E> _copy() => Set<E>.of(untrackedValue);

  @override
  int get length => value.length;

  @override
  Iterator<E> get iterator => value.iterator;

  @override
  bool contains(Object? element) {
    value;
    return untrackedValue.contains(element);
  }

  @override
  E? lookup(Object? element) {
    value;
    return untrackedValue.lookup(element);
  }

  @override
  bool add(E value) {
    final current = untrackedValue;
    if (current.contains(value)) return false;
    final next = Set<E>.of(current)..add(value);
    this.value = next;
    return true;
  }

  @override
  void addAll(Iterable<E> elements) {
    if (elements.isEmpty) return;
    final next = _copy()..addAll(elements);
    if (next.length == untrackedValue.length) return;
    value = next;
  }

  @override
  bool remove(Object? value) {
    final current = untrackedValue;
    if (!current.contains(value)) return false;
    final next = Set<E>.of(current)..remove(value);
    this.value = next;
    return true;
  }

  @override
  void removeAll(Iterable<Object?> elements) {
    if (elements.isEmpty) return;
    final current = untrackedValue;
    final next = Set<E>.of(current)..removeAll(elements);
    if (next.length == current.length) return;
    value = next;
  }

  @override
  void retainAll(Iterable<Object?> elements) {
    final current = untrackedValue;
    final next = Set<E>.of(current)..retainAll(elements);
    if (next.length == current.length) return;
    value = next;
  }

  @override
  void removeWhere(bool Function(E element) test) {
    final current = untrackedValue;
    final next = Set<E>.of(current)..removeWhere(test);
    if (next.length == current.length) return;
    value = next;
  }

  @override
  void retainWhere(bool Function(E element) test) {
    final current = untrackedValue;
    final next = Set<E>.of(current)..retainWhere(test);
    if (next.length == current.length) return;
    value = next;
  }

  @override
  void clear() {
    if (untrackedValue.isEmpty) return;
    value = <E>{};
  }

  @override
  Set<E> toSet() => Set<E>.of(untrackedValue);

  @override
  Set<R> cast<R>() => ReactiveSet<R>(untrackedValue.cast<R>());

  @override
  String toString() =>
      'ReactiveSet<$E>(value: ${untrackedValue}, previousValue: ${untrackedPreviousValue})';
}

class ReactiveMap<K, V> extends Signal<Map<K, V>> with MapMixin<K, V> {
  ReactiveMap(
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

  Map<K, V> _copy() => Map<K, V>.of(untrackedValue);

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
    final next = Map<K, V>.of(current);
    next[key] = value;
    this.value = next;
  }

  @override
  void clear() {
    if (untrackedValue.isEmpty) return;
    value = <K, V>{};
  }

  @override
  Iterable<K> get keys {
    value;
    return untrackedValue.keys;
  }

  @override
  V? remove(Object? key) {
    final current = untrackedValue;
    if (!current.containsKey(key)) return null;
    final next = Map<K, V>.of(current);
    final removed = next.remove(key);
    value = next;
    return removed;
  }

  @override
  int get length {
    value;
    return untrackedValue.length;
  }

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
  bool containsKey(Object? key) {
    value;
    return untrackedValue.containsKey(key);
  }

  @override
  bool containsValue(Object? candidate) {
    this.value;
    return untrackedValue.containsValue(candidate);
  }

  @override
  void addAll(Map<K, V> other) {
    if (other.isEmpty) return;
    final next = _copy()..addAll(other);
    if (next.length == untrackedValue.length) return;
    value = next;
  }

  @override
  V putIfAbsent(K key, V Function() ifAbsent) {
    final current = untrackedValue;
    if (current.containsKey(key)) {
      return current[key] as V;
    }
    final next = Map<K, V>.of(current);
    final value = ifAbsent();
    next[key] = value;
    this.value = next;
    return value;
  }

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
      final next = Map<K, V>.of(current);
      final value = ifAbsent();
      next[key] = value;
      this.value = next;
      return value;
    }

    final next = Map<K, V>.of(current);
    final value = update(next[key] as V);
    next[key] = value;
    this.value = next;
    return value;
  }

  @override
  void updateAll(V Function(K key, V value) update) {
    final current = untrackedValue;
    if (current.isEmpty) return;
    final next = Map<K, V>.of(current);
    next.updateAll(update);
    if (next.length == current.length &&
        next.keys.every((key) {
          return current.containsKey(key) && current[key] == next[key];
        })) {
      return;
    }
    value = next;
  }

  @override
  void removeWhere(bool Function(K key, V value) test) {
    final current = untrackedValue;
    if (current.isEmpty) return;
    final next = Map<K, V>.of(current)..removeWhere(test);
    if (next.length == current.length) return;
    value = next;
  }

  @override
  Map<RK, RV> cast<RK, RV>() =>
      ReactiveMap<RK, RV>(untrackedValue.cast<RK, RV>());

  @override
  String toString() =>
      'ReactiveMap<$K, $V>(value: ${untrackedValue}, previousValue: ${untrackedPreviousValue})';
}

class Computed<T> extends preset.ComputedNode<T>
    with DisposableMixin
    implements ReadonlySignal<T> {
  Computed(
    ValueGetter<T> getter, {
    this.equals = identical,
    bool? autoDispose,
    String? name,
    bool? trackPreviousValue,
    bool? trackInDevTools,
  }) : autoDispose = autoDispose ?? SolidartConfig.autoDispose,
       trackPreviousValue =
           trackPreviousValue ?? SolidartConfig.trackPreviousValue,
       trackInDevTools = trackInDevTools ?? SolidartConfig.devToolsEnabled,
       identifier = ._(name),
       super(flags: system.ReactiveFlags.none, getter: (_) => getter()) {
    _notifySignalCreation(this);
  }

  @override
  final bool autoDispose;

  @override
  final Identifier identifier;

  @override
  final ValueComparator<T> equals;

  @override
  final bool trackPreviousValue;

  @override
  final bool trackInDevTools;

  Option<T> _previousValue = const None();

  @override
  T get value {
    assert(!isDisposed, 'Computed is disposed');
    return get();
  }

  @override
  T get untrackedValue {
    if (currentValue != null || null is T) {
      return currentValue as T;
    }

    final prevSub = preset.setActiveSub();
    try {
      return value;
    } finally {
      preset.activeSub = prevSub;
    }
  }

  @override
  T? get previousValue {
    if (!trackPreviousValue) return null;
    value;
    return _previousValue.safeUnwrap();
  }

  @override
  T? get untrackedPreviousValue {
    if (!trackPreviousValue) return null;
    return _previousValue.safeUnwrap();
  }

  @override
  void dispose() {
    if (isDisposed) return;
    Disposable.unlinkSubs(this);
    Disposable.unlinkDeps(this);
    preset.stop(this);
    super.dispose();
    _notifySignalDisposal(this);
  }

  @override
  bool didUpdate() {
    preset.cycle++;
    depsTail = null;
    flags = system.ReactiveFlags.mutable | system.ReactiveFlags.recursedCheck;

    final prevSub = preset.setActiveSub(this);
    try {
      final previousValue = currentValue;
      final pendingValue = getter(previousValue);
      if (equals(previousValue, pendingValue)) {
        return false;
      }

      if (trackPreviousValue && (previousValue is T)) {
        _previousValue = Some(previousValue);
      }

      currentValue = pendingValue;
      _notifySignalUpdate(this);
      return true;
    } finally {
      preset.activeSub = prevSub;
      flags &= ~system.ReactiveFlags.recursedCheck;
      preset.purgeDeps(this);
    }
  }
}

class Effect extends preset.EffectNode
    with DisposableMixin
    implements Disposable, Configuration {
  factory Effect(
    VoidCallback callback, {
    bool? autoDispose,
    String? name,
    bool? detach,
  }) => .manual(
    callback,
    autoDispose: autoDispose,
    name: name,
    detach: detach,
  )..run();

  Effect.manual(
    VoidCallback callback, {
    bool? autoDispose,
    String? name,
    bool? detach,
  }) : autoDispose = autoDispose ?? SolidartConfig.autoDispose,
       identifier = ._(name),
       detach = detach ?? SolidartConfig.detachEffects,
       super(
         fn: callback,
         flags:
             system.ReactiveFlags.watching | system.ReactiveFlags.recursedCheck,
       );

  @override
  final bool autoDispose;

  @override
  final Identifier identifier;

  final bool detach;

  void run() {
    final prevSub = preset.setActiveSub(this);
    if (!detach && prevSub != null) {
      preset.link(this, prevSub, 0);
    }

    try {
      fn();
    } finally {
      preset.activeSub = prevSub;
      flags &= ~system.ReactiveFlags.recursedCheck;
    }
  }

  @override
  void dispose() {
    if (isDisposed) return;
    Disposable.unlinkDeps(this);
    preset.stop(this);
    super.dispose();
  }
}

class Resource<T> extends Signal<ResourceState<T>> {
  Resource(
    this.fetcher, {
    this.source,
    this.lazy = true,
    bool? useRefreshing,
    bool? trackPreviousState,
    this.debounceDelay,
    bool? autoDispose,
    String? name,
    bool? trackInDevTools,
    ValueComparator<ResourceState<T>> equals = identical,
  }) : stream = null,
       useRefreshing = useRefreshing ?? SolidartConfig.useRefreshing,
       super(
         ResourceState<T>.loading(),
         autoDispose: autoDispose,
         name: name,
         equals: equals,
         trackPreviousValue:
             trackPreviousState ?? SolidartConfig.trackPreviousValue,
         trackInDevTools: trackInDevTools,
       ) {
    if (!lazy) {
      _resolveIfNeeded();
    }
  }

  Resource.stream(
    this.stream, {
    this.source,
    this.lazy = true,
    bool? useRefreshing,
    bool? trackPreviousState,
    this.debounceDelay,
    bool? autoDispose,
    String? name,
    bool? trackInDevTools,
    ValueComparator<ResourceState<T>> equals = identical,
  }) : fetcher = null,
       useRefreshing = useRefreshing ?? SolidartConfig.useRefreshing,
       super(
         ResourceState<T>.loading(),
         autoDispose: autoDispose,
         name: name,
         equals: equals,
         trackPreviousValue:
             trackPreviousState ?? SolidartConfig.trackPreviousValue,
         trackInDevTools: trackInDevTools,
       ) {
    if (!lazy) {
      _resolveIfNeeded();
    }
  }

  final ReadonlySignal<dynamic>? source;
  final Future<T> Function()? fetcher;
  final Stream<T> Function()? stream;
  final bool lazy;
  final bool useRefreshing;
  final Duration? debounceDelay;

  bool _resolved = false;
  int _version = 0;
  Future<void>? _resolveFuture;
  Effect? _sourceEffect;
  StreamSubscription<T>? _streamSubscription;
  Timer? _debounceTimer;

  ResourceState<T> get state {
    _resolveIfNeeded();
    return value;
  }

  set state(ResourceState<T> next) => value = next;

  ResourceState<T>? get previousState {
    _resolveIfNeeded();
    if (!_resolved) return null;
    return previousValue;
  }

  ResourceState<T> get untrackedState => untrackedValue;

  ResourceState<T>? get untrackedPreviousState => untrackedPreviousValue;

  Future<void> resolve() async {
    if (isDisposed) return;
    if (_resolveFuture != null) return _resolveFuture!;
    if (_resolved) return;

    _resolved = true;
    _resolveFuture = _doResolve().whenComplete(() {
      _resolveFuture = null;
    });

    return _resolveFuture!;
  }

  Future<void> refresh() async {
    if (!_resolved) {
      await resolve();
      return;
    }

    if (fetcher != null) {
      return _refetch();
    }

    if (stream != null) {
      _resubscribe();
      return;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _sourceEffect?.dispose();
    _sourceEffect = null;
    _streamSubscription?.cancel();
    _streamSubscription = null;
    super.dispose();
  }

  void _resolveIfNeeded() {
    if (!_resolved) {
      unawaited(resolve());
    }
  }

  Future<void> _doResolve() async {
    if (fetcher != null) {
      await _fetch();
    }

    if (stream != null) {
      _subscribe();
    }

    if (source != null) {
      _setupSourceEffect();
    }
  }

  void _setupSourceEffect() {
    var skipped = false;
    _sourceEffect = Effect(
      () {
        source!.value;
        if (!skipped) {
          skipped = true;
          return;
        }
        if (debounceDelay != null) {
          _debounceTimer?.cancel();
          _debounceTimer = Timer(debounceDelay!, () {
            if (isDisposed) return;
            untracked(refresh);
          });
        } else {
          untracked(refresh);
        }
      },
      autoDispose: false,
    );
  }

  Future<void> _fetch() async {
    final requestId = ++_version;
    try {
      final result = await fetcher!();
      if (_isStale(requestId)) return;
      state = ResourceState<T>.ready(result);
    } catch (e, s) {
      if (_isStale(requestId)) return;
      state = ResourceState<T>.error(e, stackTrace: s);
    }
  }

  Future<void> _refetch() async {
    _transition();
    return _fetch();
  }

  void _subscribe() {
    _listenStream();
  }

  void _resubscribe() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _transition();
    _listenStream();
  }

  void _listenStream() {
    final requestId = ++_version;
    _streamSubscription = stream!().listen(
      (data) {
        if (_isStale(requestId)) return;
        state = ResourceState<T>.ready(data);
      },
      onError: (Object error, StackTrace stackTrace) {
        if (_isStale(requestId)) return;
        state = ResourceState<T>.error(error, stackTrace: stackTrace);
      },
    );
  }

  bool _isStale(int requestId) => requestId != _version || isDisposed;

  void _transition() {
    if (!useRefreshing) {
      state = ResourceState<T>.loading();
      return;
    }
    state.map(
      ready: (ready) {
        state = ready.copyWith(isRefreshing: true);
      },
      error: (error) {
        state = error.copyWith(isRefreshing: true);
      },
      loading: (_) {
        state = ResourceState<T>.loading();
      },
    );
  }
}

@sealed
@immutable
sealed class ResourceState<T> {
  const factory ResourceState.ready(T data, {bool isRefreshing}) =
      ResourceReady<T>;
  const factory ResourceState.loading() = ResourceLoading<T>;
  const factory ResourceState.error(
    Object error, {
    StackTrace? stackTrace,
    bool isRefreshing,
  }) = ResourceError<T>;

  const ResourceState();

  R map<R>({
    required R Function(ResourceReady<T> ready) ready,
    required R Function(ResourceError<T> error) error,
    required R Function(ResourceLoading<T> loading) loading,
  });
}

@immutable
class ResourceReady<T> implements ResourceState<T> {
  const ResourceReady(this.value, {this.isRefreshing = false});

  final T value;
  final bool isRefreshing;

  @override
  R map<R>({
    required R Function(ResourceReady<T> ready) ready,
    required R Function(ResourceError<T> error) error,
    required R Function(ResourceLoading<T> loading) loading,
  }) {
    return ready(this);
  }

  ResourceReady<T> copyWith({
    T? value,
    bool? isRefreshing,
  }) {
    return ResourceReady<T>(
      value ?? this.value,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  String toString() {
    return 'ResourceReady<$T>(value: $value, refreshing: $isRefreshing)';
  }

  @override
  bool operator ==(Object other) {
    return runtimeType == other.runtimeType &&
        other is ResourceReady<T> &&
        other.value == value &&
        other.isRefreshing == isRefreshing;
  }

  @override
  int get hashCode => Object.hash(runtimeType, value, isRefreshing);
}

@immutable
class ResourceLoading<T> implements ResourceState<T> {
  const ResourceLoading();

  @override
  R map<R>({
    required R Function(ResourceReady<T> ready) ready,
    required R Function(ResourceError<T> error) error,
    required R Function(ResourceLoading<T> loading) loading,
  }) {
    return loading(this);
  }

  @override
  String toString() => 'ResourceLoading<$T>()';

  @override
  bool operator ==(Object other) => runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}

@immutable
class ResourceError<T> implements ResourceState<T> {
  const ResourceError(
    this.error, {
    this.stackTrace,
    this.isRefreshing = false,
  });

  final Object error;
  final StackTrace? stackTrace;
  final bool isRefreshing;

  @override
  R map<R>({
    required R Function(ResourceReady<T> ready) ready,
    required R Function(ResourceError<T> error) error,
    required R Function(ResourceLoading<T> loading) loading,
  }) {
    return error(this);
  }

  ResourceError<T> copyWith({
    Object? error,
    StackTrace? stackTrace,
    bool? isRefreshing,
  }) {
    return ResourceError<T>(
      error ?? this.error,
      stackTrace: stackTrace ?? this.stackTrace,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  String toString() {
    return 'ResourceError<$T>(error: $error, stackTrace: $stackTrace, '
        'refreshing: $isRefreshing)';
  }

  @override
  bool operator ==(Object other) {
    return runtimeType == other.runtimeType &&
        other is ResourceError<T> &&
        other.error == error &&
        other.stackTrace == stackTrace &&
        other.isRefreshing == isRefreshing;
  }

  @override
  int get hashCode => Object.hash(runtimeType, error, stackTrace, isRefreshing);
}

extension ResourceStateExtensions<T> on ResourceState<T> {
  bool get isLoading => this is ResourceLoading<T>;
  bool get hasError => this is ResourceError<T>;
  bool get isReady => this is ResourceReady<T>;
  bool get isRefreshing => switch (this) {
    ResourceReady<T>(:final isRefreshing) => isRefreshing,
    ResourceError<T>(:final isRefreshing) => isRefreshing,
    ResourceLoading<T>() => false,
  };

  ResourceReady<T>? get asReady => map(
    ready: (r) => r,
    error: (_) => null,
    loading: (_) => null,
  );

  ResourceError<T>? get asError => map(
    error: (e) => e,
    ready: (_) => null,
    loading: (_) => null,
  );

  T? get value => map(
    ready: (r) => r.value,
    // ignore: only_throw_errors
    error: (r) => throw r.error,
    loading: (_) => null,
  );

  Object? get error => map(
    error: (r) => r.error,
    ready: (_) => null,
    loading: (_) => null,
  );

  R when<R>({
    required R Function(T data) ready,
    required R Function(Object error, StackTrace? stackTrace) error,
    required R Function() loading,
  }) {
    return map(
      ready: (r) => ready(r.value),
      error: (e) => error(e.error, e.stackTrace),
      loading: (_) => loading(),
    );
  }

  R maybeWhen<R>({
    required R Function() orElse,
    R Function(T data)? ready,
    R Function(Object error, StackTrace? stackTrace)? error,
    R Function()? loading,
  }) {
    return map(
      ready: (r) {
        if (ready != null) return ready(r.value);
        return orElse();
      },
      error: (e) {
        if (error != null) return error(e.error, e.stackTrace);
        return orElse();
      },
      loading: (l) {
        if (loading != null) return loading();
        return orElse();
      },
    );
  }

  R maybeMap<R>({
    required R Function() orElse,
    R Function(ResourceReady<T> ready)? ready,
    R Function(ResourceError<T> error)? error,
    R Function(ResourceLoading<T> loading)? loading,
  }) {
    return map(
      ready: (r) {
        if (ready != null) return ready(r);
        return orElse();
      },
      error: (e) {
        if (error != null) return error(e);
        return orElse();
      },
      loading: (l) {
        if (loading != null) return loading(l);
        return orElse();
      },
    );
  }
}

mixin DisposableMixin implements Disposable {
  @internal
  late final cleanups = <VoidCallback>[];

  @override
  bool isDisposed = false;

  @mustCallSuper
  @override
  void onDispose(VoidCallback callback) {
    cleanups.add(callback);
  }

  @mustCallSuper
  @override
  void dispose() {
    if (isDisposed) return;
    isDisposed = true;
    try {
      for (final callback in cleanups) {
        callback();
      }
    } finally {
      cleanups.clear();
    }
  }
}
