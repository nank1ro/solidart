// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert' as convert;
import 'dart:developer' as developer;

import 'package:meta/meta.dart';
import 'package:solidart/deps/preset.dart' as preset;
import 'package:solidart/deps/system.dart' as system;

typedef ValueComparator<T> = bool Function(T a, T b);
typedef VoidCallback = void Function();

T batch<T>(T Function() callback) {
  preset.startBatch();
  try {
    return callback();
  } finally {
    preset.endBatch();
  }
}

T untracked<T>(T Function() callback) {
  final prevSub = preset.setActiveSub();
  try {
    return callback();
  } finally {
    preset.setActiveSub(prevSub);
  }
}

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
  final T value;

  const Some(this.value);
}

final class None<T> extends Option<T> {
  const None();
}

abstract class SolidartConfig {
  static bool equals = false;
  static bool autoDispose = true;
  static bool devToolsEnabled = false;
  static bool trackPreviousValue = true;
  static bool useRefreshing = true;
  static bool assertSignalBuilderWithoutDependencies = true;
  static final observers = <SolidartObserver>[];
  static bool detachEffects = false;
}

abstract class SolidartObserver {
  // coverage:ignore-start
  const SolidartObserver();
  // coverage:ignore-end

  void didCreateSignal(ReadonlySignal<Object?> signal);
  void didUpdateSignal(ReadonlySignal<Object?> signal);
  void didDisposeSignal(ReadonlySignal<Object?> signal);
}

mixin Disposable {
  bool _disposed = false;
  final List<VoidCallback> _onDisposeCallbacks = [];

  bool get disposed => _disposed;

  @mustCallSuper
  void dispose() {
    if (disposed) return;
    try {
      for (final callback in _onDisposeCallbacks) {
        callback();
      }
    } finally {
      _disposed = true;
      _onDisposeCallbacks.clear();
    }
  }

  void onDispose(VoidCallback callback) => _onDisposeCallbacks.add(callback);
}

abstract interface class ReadonlySignal<T> implements Disposable {
  String? get name;
  bool get equals;
  ValueComparator<T> get comparator;
  bool get autoDispose;
  bool get trackInDevTools;
  bool get trackPreviousValue;
  int get listenerCount;

  T get value;
  set value(T newValue);
  bool get hasValue;
  T get untrackedValue;

  T? get previousValue;
  T? get untrackedPreviousValue;
  bool get hasPreviousValue;

  T call();
}

class Signal<T> extends preset.SignalNode<Option<T>>
    with Disposable
    implements ReadonlySignal<T> {
  @override
  final bool autoDispose;

  @override
  final ValueComparator<T> comparator;

  @override
  final bool equals;

  @override
  final String? name;

  @override
  final bool trackInDevTools;

  @override
  final bool trackPreviousValue;

  @override
  bool hasValue;

  @override
  bool hasPreviousValue = false;

  T? _untrackedPreviousValue;

  Signal(
    T initialValue, {
    ValueComparator<T>? comparator,
    String? name,
    bool? autoDispose,
    bool? equals,
    bool? trackInDevTools,
    bool? trackPreviousValue,
  }) : this._internal(
         Some(initialValue),
         hasValue: true,
         comparator: comparator ?? identical,
         name: name,
         autoDispose: autoDispose,
         equals: equals,
         trackInDevTools: trackInDevTools,
         trackPreviousValue: trackPreviousValue,
       );

  Signal.lazy({
    ValueComparator<T>? comparator,
    String? name,
    bool? autoDispose,
    bool? equals,
    bool? trackInDevTools,
    bool? trackPreviousValue,
  }) : this._internal(
         const None(),
         hasValue: false,
         comparator: comparator ?? identical,
         name: name,
         autoDispose: autoDispose,
         equals: equals,
         trackInDevTools: trackInDevTools,
         trackPreviousValue: trackPreviousValue,
       );

  Signal._internal(
    Option<T> initialValue, {
    required this.hasValue,
    required this.comparator,
    this.name,
    bool? autoDispose,
    bool? equals,
    bool? trackInDevTools,
    bool? trackPreviousValue,
  }) : autoDispose = autoDispose ?? SolidartConfig.autoDispose,
       equals = equals ?? SolidartConfig.equals,
       trackInDevTools = trackInDevTools ?? SolidartConfig.devToolsEnabled,
       trackPreviousValue =
           trackPreviousValue ?? SolidartConfig.trackPreviousValue,
       super(
         flags: system.ReactiveFlags.mutable,
         currentValue: initialValue,
         pendingValue: initialValue,
       );

  @override
  T? get untrackedPreviousValue {
    if (hasPreviousValue) return _untrackedPreviousValue;
    throw StateError('Signal has no previous value');
  }

  @override
  T? get previousValue {
    if (trackPreviousValue) get();
    return untrackedPreviousValue;
  }

  @override
  T get value {
    if (hasValue) return get().unwrap();
    throw StateError('Signal has no value');
  }

  @override
  set value(T newValue) {
    final oldValue = pendingValue.safeUnwrap();
    if (!hasValue) {
      hasValue = true;
      set(Some(newValue));
      SolidartConfig.observers.emit(.created, this);
      return;
    }
    if ((!equals && !comparator(oldValue as T, newValue)) ||
        (equals && oldValue != newValue)) {
      return;
    }

    final prevHasPreviousValue = hasPreviousValue;
    _untrackedPreviousValue = oldValue;
    if (!prevHasPreviousValue) {
      hasPreviousValue = true;
      SolidartConfig.observers.emit(.created, this);
    }

    set(Some(newValue));
    if (prevHasPreviousValue) {
      SolidartConfig.observers.emit(.updated, this);
    }
  }

  @override
  T get untrackedValue => currentValue.unwrap();

  @override
  // TODO: implement listenerCount
  int get listenerCount => throw UnimplementedError();

  @override
  T call() => value;

  ReadonlySignal<T> toReadonlySignal() => this;
}

// TODO
class Computed<T> extends preset.ComputedNode<T>
    with Disposable
    implements ReadonlySignal<T> {}

// TODO
class Effect extends preset.EffectNode with Disposable {
  // 额外需要此设置！
  final bool detach;
}

enum _ObserverEvent { created, updated, disposed }

final class _DevTools {
  const _DevTools();

  static void emit(_ObserverEvent event, ReadonlySignal<Object?> signal) {
    assert(() {
      final kind = 'ext.solidart.signal.${event.name}';
      var value = signal.value;
      var previousValue = signal.previousValue;
      // TODO:
      // if (signal is Resource) {
      //   value = signal._value.asReady?.value;
      //   previousValue = signal._previousValue?.asReady?.value;
      // }

      developer.postEvent(kind, {
        // '_id': signal._id,
        'name': signal.name,
        'value': trySerializeJson(value),
        'previousValue': trySerializeJson(previousValue),
        'hasPreviousValue': signal.hasPreviousValue,
        'type': switch (signal) {
          // TODO:
          // Resource() => 'Resource',
          // ListSignal() => 'ListSignal',
          // MapSignal() => 'MapSignal',
          // SetSignal() => 'SetSignal',
          // Signal() => 'Signal',
          // Computed() => 'Computed',
          ReadonlySignal() => 'ReadonlySignal',
        },
        'valueType': value.runtimeType.toString(),
        if (signal.hasPreviousValue)
          'previousValueType': previousValue.runtimeType.toString(),
        'disposed': signal.disposed,
        'autoDispose': signal.autoDispose,
        'listenerCount': signal.listenerCount,
        'lastUpdate': DateTime.now().toIso8601String(),
      });
      return true;
    }(), 'Post devtools event assertion failed');
  }

  static Object? trySerializeJson(Object? value) {
    try {
      return convert.json.encode(value);
    } catch (_) {
      return switch (value) {
        Iterable() => trySerializeJson(value.map(trySerializeJson).toList()),
        Map() => trySerializeJson(
          value.map(
            (key, value) =>
                MapEntry(trySerializeJson(key), trySerializeJson(value)),
          ),
        ),
        _ => convert.json.encode(value),
      };
    }
  }
}

extension on Iterable<SolidartObserver> {
  void emit(_ObserverEvent event, ReadonlySignal<Object?> signal) {
    _DevTools.emit(event, signal);
    for (final observer in this) {
      try {
        switch (event) {
          case .created:
            observer.didCreateSignal(signal);
          case .updated:
            observer.didUpdateSignal(signal);
          case .disposed:
            observer.didDisposeSignal(signal);
        }
      } catch (_) {}
    }
  }
}
