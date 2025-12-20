import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:math';

import 'package:meta/meta.dart';
import 'package:solidart/deps/preset.dart' as preset;
import 'package:solidart/deps/system.dart' as system;

/// Compares two values for equality.
///
/// Return `true` when the update should be skipped because values are
/// considered equivalent.
typedef ValueComparator<T> = bool Function(T? a, T? b);

/// Lazily produces a value.
typedef ValueGetter<T> = T Function();

/// A callback that returns no value.
typedef VoidCallback = ValueGetter<void>;

/// An optional value container.
///
/// Use [Some] to represent presence and [None] to represent absence without
/// relying on `null`.
sealed class Option<T> {
  /// Base constructor for option values.
  const Option();

  /// Returns the contained value or throws if this is [None].
  T unwrap() => switch (this) {
    Some<T>(:final value) => value,
    _ => throw StateError('Option is None'),
  };

  /// Returns the contained value or `null` if this is [None].
  T? safeUnwrap() => switch (this) {
    Some<T>(:final value) => value,
    _ => null,
  };
}

/// A present optional value.
final class Some<T> extends Option<T> {
  /// Creates an option that wraps [value].
  const Some(this.value);

  /// The wrapped value.
  final T value;
}

/// An absent optional value.
final class None<T> extends Option<T> {
  /// Creates an option with no value.
  const None();
}

/// {@template v3-config}
/// Global configuration for v3 reactive primitives.
///
/// These flags provide defaults for newly created signals/effects/resources.
/// You can override them per-instance via constructor parameters.
/// {@endtemplate}
final class SolidartConfig {
  const SolidartConfig._();

  /// Whether nodes auto-dispose when they lose all subscribers.
  ///
  /// When enabled, signals/computeds/effects may dispose themselves once
  /// nothing depends on them.
  static bool autoDispose = false;

  /// Whether nested effects detach from parent subscriptions.
  ///
  /// When `true`, inner effects do not become dependencies of their parent
  /// effect unless explicitly linked.
  static bool detachEffects = false;

  /// Whether to track previous values by default.
  ///
  /// Previous values are captured only after a signal has been read at least
  /// once.
  static bool trackPreviousValue = true;

  /// Whether to keep values while refreshing resources.
  ///
  /// When `true`, a refresh marks the state as `isRefreshing` instead of
  /// replacing it with `loading`.
  static bool useRefreshing = true;

  /// Whether DevTools tracking is enabled.
  ///
  /// Signals only emit DevTools events when both this flag and
  /// `trackInDevTools` are `true`.
  static bool devToolsEnabled = false;

  /// Registered observers for signal lifecycle events.
  ///
  /// Observers are notified only when `trackInDevTools` is enabled for the
  /// signal instance.
  static final observers = <SolidartObserver>[];
}

/// {@template v3-observer}
/// Observer for signal lifecycle events.
///
/// Use this for logging or instrumentation without depending on DevTools:
/// ```dart
/// class Logger extends SolidartObserver {
///   @override
///   void didCreateSignal(ReadonlySignal<Object?> signal) {
///     print('created: ${signal.identifier.value}');
///   }
///   @override
///   void didUpdateSignal(ReadonlySignal<Object?> signal) {}
///   @override
///   void didDisposeSignal(ReadonlySignal<Object?> signal) {}
/// }
///
/// SolidartConfig.observers.add(Logger());
/// ```
/// {@endtemplate}
abstract class SolidartObserver {
  /// {@macro v3-observer}
  const SolidartObserver();

  /// Called when a signal is created.
  void didCreateSignal(ReadonlySignal<Object?> signal);

  /// Called when a signal updates.
  void didUpdateSignal(ReadonlySignal<Object?> signal);

  /// Called when a signal is disposed.
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

/// Runs [callback] without tracking dependencies.
///
/// This is useful when you want to read or write signals inside an effect
/// without establishing a dependency.
///
/// ```dart
/// final count = Signal(0);
/// Effect(() {
///   print(count.value);
///   untracked(() => count.value = count.value + 1);
/// });
/// ```
T untracked<T>(T Function() callback) {
  final prevSub = preset.setActiveSub();
  try {
    return callback();
  } finally {
    preset.setActiveSub(prevSub);
  }
}

/// Batches signal updates and flushes once at the end.
///
/// Nested batches are supported; the final flush happens when the outermost
/// batch completes.
///
/// ```dart
/// final a = Signal(1);
/// final b = Signal(2);
/// Effect(() => print('sum: ${a.value + b.value}'));
///
/// batch(() {
///   a.value = 3;
///   b.value = 4;
/// });
/// ```
T batch<T>(T Function() fn) {
  preset.startBatch();
  try {
    return fn();
  } finally {
    preset.endBatch();
  }
}

/// A unique identifier with an optional name.
///
/// Used by DevTools and diagnostics to track instances.
class Identifier {
  Identifier._(this.name) : value = _counter++;
  static int _counter = 0;

  /// Optional human-readable name.
  final String? name;

  /// Unique numeric identifier.
  final int value;
}

/// Base configuration shared by reactive primitives.
abstract interface class Configuration {
  /// Identifier for the instance.
  Identifier get identifier;

  /// Whether the instance auto-disposes.
  bool get autoDispose;
}

/// Disposable behavior for reactive primitives.
abstract class Disposable {
  /// Whether this instance has been disposed.
  bool get isDisposed;

  /// Registers a callback to run on dispose.
  void onDispose(VoidCallback callback);

  /// Disposes the instance.
  void dispose();

  /// Whether the node can be auto-disposed.
  static bool canAutoDispose(system.ReactiveNode node) => switch (node) {
    Disposable(:final isDisposed) && Configuration(:final autoDispose) =>
      !isDisposed && autoDispose,
    _ => false,
  };

  /// Unlinks dependencies from a node.
  ///
  /// This is used to break reactive links during disposal.
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

  /// Unlinks subscribers from a node.
  ///
  /// This is used to break reactive links during disposal.
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

/// Common configuration for signals.
abstract interface class SignalConfiguration<T> implements Configuration {
  /// Comparator used to skip equal updates.
  ///
  /// When it returns `true`, the new value is treated as equal and the update
  /// is skipped.
  ValueComparator<T> get equals;

  /// Whether to track previous values.
  ///
  /// Previous values are captured on successful updates after a tracked read.
  bool get trackPreviousValue;

  /// Whether to report to DevTools.
  bool get trackInDevTools;
}

/// Read-only reactive value.
///
/// Reading [value] establishes a dependency; [untrackedValue] does not.
/// This interface is implemented by [Signal], [Computed], and [Resource].
///
/// ```dart
/// final count = Signal(0);
/// ReadonlySignal<int> readonly = count.toReadonly();
/// ```
// TODO(nank1ro): Maybe rename to `ReadSignal`? medz: I still recommend `ReadonlySignal` because it is semantically clearer., https://github.com/nank1ro/solidart/pull/166#issuecomment-3623175977
abstract interface class ReadonlySignal<T>
    implements system.ReactiveNode, Disposable, SignalConfiguration<T> {
  /// Returns the current value and tracks dependencies.
  T get value;

  /// Returns the current value without tracking.
  T get untrackedValue;

  /// Returns the previous value (tracked read).
  ///
  /// This may return `null` if tracking is disabled or the signal has not been
  /// read since the last update.
  T? get previousValue;

  /// Returns the previous value without tracking.
  T? get untrackedPreviousValue;
}

/// {@template v3-signal}
/// # Signals
/// Signals are the cornerstone of reactivity in v3. They store values that
/// change over time, and any reactive computation that reads a signal will
/// automatically update when the signal changes.
///
/// Create a signal with an initial value:
/// ```dart
/// final counter = Signal(0);
/// ```
///
/// Read the current value:
/// ```dart
/// counter.value; // 0
/// ```
///
/// Update the value:
/// ```dart
/// counter.value++;
/// // or
/// counter.value = 10;
/// ```
///
/// Signals support previous value tracking. When enabled, `previousValue`
/// updates only after the signal has been read at least once:
/// ```dart
/// final count = Signal(0);
/// count.value = 1;
/// count.previousValue; // null (not read yet)
/// count.value;         // establishes tracking
/// count.previousValue; // 0
/// ```
///
/// Signals can be created lazily using [Signal.lazy]. A lazy signal does not
/// have a value until it is first assigned, and reading it early throws
/// [StateError].
/// {@endtemplate}
/// {@template v3-signal-equals}
/// Updates are skipped when [equals] reports the new value is equivalent to
/// the previous one.
/// {@endtemplate}
class Signal<T> extends preset.SignalNode<Option<T>>
    with DisposableMixin
    implements ReadonlySignal<T> {
  /// {@macro v3-signal}
  ///
  /// {@macro v3-signal-equals}
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

  /// {@macro v3-signal}
  ///
  /// This is a lazy signal: it has no value at construction time.
  /// Reading [value] before the first assignment throws [StateError].
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

  /// Sets the current value.
  ///
  /// {@macro v3-signal-equals}
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
  /// Returns a read-only view of this signal.
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

/// A signal that starts uninitialized until first set.
///
/// This is the concrete type behind [Signal.lazy]. Reading [value] before the
/// first assignment throws [StateError].
///
/// ```dart
/// final lazy = Signal.lazy<int>();
/// lazy.value = 1;
/// print(lazy.value); // 1
/// ```
class LazySignal<T> extends Signal<T> {
  /// Creates a lazy signal.
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

  /// Whether the signal has been initialized.
  ///
  /// This becomes `true` after the first assignment.
  bool get isInitialized => currentValue is Some<T>;

  @override
  T get value {
    if (isInitialized || pendingValue is Some<T>) {
      return super.value;
    }
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

/// {@template v3-reactive-list}
/// A reactive wrapper around a [List] that copies on write.
///
/// Mutations create a new list instance so that updates are observable:
/// ```dart
/// final list = ReactiveList([1, 2]);
/// Effect(() => print(list.length));
/// list.add(3); // triggers effect
/// ```
///
/// Reads (like `length` or index access) establish dependencies; the usual
/// list API is supported.
/// {@endtemplate}
class ReactiveList<E> extends Signal<List<E>> with ListMixin<E> {
  /// {@macro v3-reactive-list}
  ///
  /// Creates a reactive list with the provided initial values.
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
    value = List<E>.of(current)..length = newLength;
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
  void replaceRange(int start, int end, Iterable<E> newContents) {
    final next = _copy()..replaceRange(start, end, newContents);
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
  void fillRange(int start, int end, [E? fill]) {
    if (end <= start) return;
    final next = _copy()..fillRange(start, end, fill);
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
      'ReactiveList<$E>(value: $untrackedValue, '
      'previousValue: $untrackedPreviousValue)';
}

/// {@template v3-reactive-set}
/// A reactive wrapper around a [Set] that copies on write.
///
/// Mutations create a new set instance so that updates are observable:
/// ```dart
/// final set = ReactiveSet({1});
/// Effect(() => print(set.length));
/// set.add(2); // triggers effect
/// ```
///
/// Reads (like `length` or `contains`) establish dependencies.
/// {@endtemplate}
class ReactiveSet<E> extends Signal<Set<E>> with SetMixin<E> {
  /// {@macro v3-reactive-set}
  ///
  /// Creates a reactive set with the provided initial values.
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
      'ReactiveSet<$E>(value: $untrackedValue, '
      'previousValue: $untrackedPreviousValue)';
}

/// {@template v3-reactive-map}
/// A reactive wrapper around a [Map] that copies on write.
///
/// Mutations create a new map instance so that updates are observable:
/// ```dart
/// final map = ReactiveMap({'a': 1});
/// Effect(() => print(map['a']));
/// map['a'] = 2; // triggers effect
/// ```
///
/// Reads (like `[]`, `keys`, or `length`) establish dependencies.
/// {@endtemplate}
class ReactiveMap<K, V> extends Signal<Map<K, V>> with MapMixin<K, V> {
  /// {@macro v3-reactive-map}
  ///
  /// Creates a reactive map with the provided initial values.
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
  bool containsValue(Object? value) {
    this.value;
    return untrackedValue.containsValue(value);
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
    final next = Map<K, V>.of(current)..updateAll(update);
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
      'ReactiveMap<$K, $V>(value: $untrackedValue, '
      'previousValue: $untrackedPreviousValue)';
}

/// {@template v3-computed}
/// # Computed
/// A computed signal derives its value from other signals. It is read-only
/// and recalculates whenever any dependency changes.
///
/// Use `Computed` to derive state or combine multiple signals:
/// ```dart
/// final firstName = Signal('Josh');
/// final lastName = Signal('Brown');
/// final fullName = Computed(() => '${firstName.value} ${lastName.value}');
/// ```
///
/// Computeds only notify when the derived value changes. You can customize
/// equality via [equals] to skip updates for equivalent values.
///
/// Like signals, computeds can track previous values once they have been read.
/// {@endtemplate}
class Computed<T> extends preset.ComputedNode<T>
    with DisposableMixin
    implements ReadonlySignal<T> {
  /// {@macro v3-computed}
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

/// {@template v3-effect}
/// # Effect
/// Effects run a side-effect whenever any signal they read changes.
///
/// ```dart
/// final counter = Signal(0);
/// Effect(() {
///   print('count: ${counter.value}');
/// });
/// ```
///
/// Effects run once immediately when created. If you need a lazy effect,
/// create it with [Effect.manual] and call [run] yourself.
///
/// Nested effects can either attach to their parent (default) or detach by
/// passing `detach: true` or by enabling [SolidartConfig.detachEffects].
///
/// Call [dispose] to stop the effect and release dependencies.
/// {@endtemplate}
class Effect extends preset.EffectNode
    with DisposableMixin
    implements Disposable, Configuration {
  /// {@macro v3-effect}
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

  /// Creates an effect without running it.
  ///
  /// Use this when you need to *delay* the first run or decide *when* the
  /// effect should start tracking dependencies. Common cases:
  /// - you must create several signals first and only then start the effect
  /// - you want to control the first run in tests
  /// - you need conditional startup (e.g. after async setup)
  ///
  /// The effect will not track anything until you call [run]:
  /// ```dart
  /// final count = Signal(0);
  /// final effect = Effect.manual(() {
  ///   print('count: ${count.value}');
  /// });
  ///
  /// count.value = 1; // no output yet
  /// effect.run();    // prints "count: 1" and starts tracking
  /// ```
  ///
  /// If you want the effect to run immediately, use the [Effect] factory.
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

  /// Whether this effect detaches from parent subscriptions.
  final bool detach;

  /// Runs the effect and tracks dependencies.
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

/// {@template v3-resource}
/// # Resource
/// A resource is a signal designed for async data. It wraps the common states
/// of asynchronous work: `ready`, `loading`, and `error`.
///
/// Resources can be driven by:
/// - a `fetcher` that returns a `Future`
/// - a `stream` that yields values over time
/// - an optional `source` signal that triggers refreshes
///
/// Example using a fetcher:
/// ```dart
/// final userId = Signal(1);
///
/// Future<String> fetchUser() async {
///   final id = userId.value;
///   return 'user:$id';
/// }
///
/// final user = Resource(fetchUser, source: userId);
/// ```
///
/// The current state is available via [state] and provides helpers like
/// `when`, `maybeWhen`, `asReady`, `asError`, `isLoading`, and `isRefreshing`.
///
/// The [resolve] method starts the resource once. The [refresh] method forces
/// a new fetch or re-subscribes to the stream. When [useRefreshing] is true,
/// refresh updates the current state with `isRefreshing` instead of resetting
/// to `loading`.
/// {@endtemplate}
class Resource<T> extends Signal<ResourceState<T>> {
  /// {@macro v3-resource}
  ///
  /// Creates a resource backed by a future-producing [fetcher].
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

  /// {@macro v3-resource}
  ///
  /// Creates a resource backed by a stream factory.
  ///
  /// Use this when your data source is an ongoing stream (e.g. sockets,
  /// Firestore snapshots, or SSE). The stream is subscribed on resolve and
  /// re-subscribed when [refresh] is called or when [source] changes.
  ///
  /// ```dart
  /// final ticks = Resource.stream(
  ///   () => Stream.periodic(const Duration(seconds: 1), (i) => i),
  ///   lazy: false,
  /// );
  /// ```
  ///
  /// When a refresh happens, the previous subscription is cancelled and
  /// events from older subscriptions are ignored.
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

  /// Optional source signal that triggers refreshes when it changes.
  ///
  /// When [source] updates, the resource refreshes. If [debounceDelay] is set,
  /// multiple source changes are coalesced.
  final ReadonlySignal<dynamic>? source;

  /// Fetches the resource value.
  final Future<T> Function()? fetcher;

  /// Provides a stream of resource values.
  final Stream<T> Function()? stream;

  /// Whether the resource is resolved lazily.
  ///
  /// When `true`, the resource resolves on first read or when [resolve] is
  /// called explicitly.
  final bool lazy;

  /// Whether to keep previous value while refreshing.
  ///
  /// When `true`, refresh updates the current state with `isRefreshing` rather
  /// than replacing it with `loading`.
  final bool useRefreshing;

  /// Optional debounce duration for source-triggered refreshes.
  final Duration? debounceDelay;

  bool _resolved = false;
  int _version = 0;
  Future<void>? _resolveFuture;
  Effect? _sourceEffect;
  StreamSubscription<T>? _streamSubscription;
  Timer? _debounceTimer;

  /// Returns the current state, resolving lazily if needed.
  ResourceState<T> get state {
    _resolveIfNeeded();
    return value;
  }

  /// Sets the current state.
  set state(ResourceState<T> next) => value = next;

  /// Returns the previous state (tracked read), or `null`.
  ///
  /// Previous state is available only after a tracked read.
  ResourceState<T>? get previousState {
    _resolveIfNeeded();
    if (!_resolved) return null;
    return previousValue;
  }

  /// Returns the current state without tracking.
  ResourceState<T> get untrackedState => untrackedValue;

  /// Returns the previous state without tracking.
  ResourceState<T>? get untrackedPreviousState => untrackedPreviousValue;

  /// Resolves the resource if it has not been resolved yet.
  ///
  /// Multiple calls are coalesced into a single in-flight resolve.
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

  /// Re-fetches or re-subscribes to the resource.
  ///
  /// If the resource has not been resolved yet, this triggers [resolve]
  /// instead.
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

/// {@template v3-resource-state}
/// Represents the state of a [Resource].
///
/// A resource is always in one of:
/// - `ready(data)` when a value is available
/// - `loading()` while work is in progress
/// - `error(error)` when a failure occurs
///
/// Use [ResourceStateExtensions] helpers to map or pattern-match:
/// ```dart
/// final state = resource.state;
/// final label = state.when(
///   ready: (data) => 'ready: $data',
///   error: (err, _) => 'error: $err',
///   loading: () => 'loading',
/// );
/// ```
/// {@endtemplate}
@sealed
@immutable
sealed class ResourceState<T> {
  /// Base constructor for resource states.
  const ResourceState();

  /// {@macro v3-resource-state}
  ///
  /// Creates a ready state with [data].
  const factory ResourceState.ready(T data, {bool isRefreshing}) =
      ResourceReady<T>;

  /// {@macro v3-resource-state}
  ///
  /// Creates a loading state.
  const factory ResourceState.loading() = ResourceLoading<T>;

  /// {@macro v3-resource-state}
  ///
  /// Creates an error state.
  const factory ResourceState.error(
    Object error, {
    StackTrace? stackTrace,
    bool isRefreshing,
  }) = ResourceError<T>;

  /// Maps each concrete state to a value.
  R map<R>({
    required R Function(ResourceReady<T> ready) ready,
    required R Function(ResourceError<T> error) error,
    required R Function(ResourceLoading<T> loading) loading,
  });
}

/// Ready state containing data.
@immutable
class ResourceReady<T> implements ResourceState<T> {
  /// Creates a ready state with [value].
  const ResourceReady(this.value, {this.isRefreshing = false});

  /// The resource value.
  final T value;

  /// Whether the resource is refreshing.
  final bool isRefreshing;

  @override
  R map<R>({
    required R Function(ResourceReady<T> ready) ready,
    required R Function(ResourceError<T> error) error,
    required R Function(ResourceLoading<T> loading) loading,
  }) {
    return ready(this);
  }

  /// Returns a copy with updated fields.
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

/// Loading state.
@immutable
class ResourceLoading<T> implements ResourceState<T> {
  /// Creates a loading state.
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

/// Error state containing an error and optional stack trace.
@immutable
class ResourceError<T> implements ResourceState<T> {
  /// Creates an error state.
  const ResourceError(
    this.error, {
    this.stackTrace,
    this.isRefreshing = false,
  });

  /// The error object.
  final Object error;

  /// Optional stack trace.
  final StackTrace? stackTrace;

  /// Whether the resource is refreshing.
  final bool isRefreshing;

  @override
  R map<R>({
    required R Function(ResourceReady<T> ready) ready,
    required R Function(ResourceError<T> error) error,
    required R Function(ResourceLoading<T> loading) loading,
  }) {
    return error(this);
  }

  /// Returns a copy with updated fields.
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

/// Convenience accessors for [ResourceState].
///
/// Includes common flags (`isLoading`, `isReady`, `hasError`), casting helpers
/// (`asReady`, `asError`), and pattern matching helpers (`when`, `maybeWhen`,
/// `maybeMap`).
extension ResourceStateExtensions<T> on ResourceState<T> {
  /// Whether this state is loading.
  bool get isLoading => this is ResourceLoading<T>;

  /// Whether this state is an error.
  bool get hasError => this is ResourceError<T>;

  /// Whether this state is ready.
  bool get isReady => this is ResourceReady<T>;

  /// Whether this state is marked as refreshing.
  bool get isRefreshing => switch (this) {
    ResourceReady<T>(:final isRefreshing) => isRefreshing,
    ResourceError<T>(:final isRefreshing) => isRefreshing,
    ResourceLoading<T>() => false,
  };

  /// Casts to [ResourceReady] if possible.
  ResourceReady<T>? get asReady => map(
    ready: (r) => r,
    error: (_) => null,
    loading: (_) => null,
  );

  /// Casts to [ResourceError] if possible.
  ResourceError<T>? get asError => map(
    error: (e) => e,
    ready: (_) => null,
    loading: (_) => null,
  );

  /// Returns the value for ready state, throws for error state.
  T? get value => map(
    ready: (r) => r.value,
    // ignore: only_throw_errors
    error: (r) => throw r.error,
    loading: (_) => null,
  );

  /// Returns the error for error state.
  Object? get error => map(
    error: (r) => r.error,
    ready: (_) => null,
    loading: (_) => null,
  );

  /// Executes callbacks for each state.
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

  /// Executes callbacks for available handlers, otherwise [orElse].
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

  /// Executes callbacks for available handlers, otherwise [orElse].
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

/// Default [Disposable] implementation using cleanup callbacks.
mixin DisposableMixin implements Disposable {
  @internal
  /// Registered cleanup callbacks invoked on dispose.
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
