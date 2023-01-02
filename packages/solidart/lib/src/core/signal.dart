import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:solidart/solidart.dart';
import 'package:solidart/src/core/signal_selector.dart';

/// Creates a simple reactive state with a getter and setter.
///
/// When you change a signal's value, it automatically updates any listener.
Signal<T> createSignal<T>(
  T value, {
  SignalOptions<T>? options,
}) {
  final effectiveOptions = options ?? SignalOptions<T>();
  return Signal<T>(value, options: effectiveOptions);
}

class Signal<T> implements BaseSignal<T> {
  Signal(
    T initialValue, {
    required this.options,
  }) : _value = initialValue;

  T _value;

  @override
  T get value => _value;

  @override
  final SignalOptions<T> options;

  bool _disposed = false;

  final _listeners = <VoidCallback>{};
  int _version = 0;
  int _microtaskVersion = 0;
  // Keeps track of all the callbacks passed to [onDispose].
  // Used later to fire each callback when this signal is disposed.
  final _onDisposeCallbacks = <VoidCallback>[];

  /// Updates the current signal value with [newValue].
  ///
  /// This operation may be skipped if the value is equal to the previous one,
  /// check [SignalOptions.equals] and [SignalOptions.comparator].
  set value(T newValue) {
    // skip if the value are equals
    // TODO(alex): add specific equality based on type, e.g. DeepCollectionEquality
    if (options.equals && value == newValue) {
      return;
    }

    // skip if the [comparator] returns true
    if (!options.equals && options.comparator != null) {
      final areEqual = options.comparator!(value, newValue);
      if (areEqual) return;
    }

    // store the previous value
    _previousValue = value;
    // notify with the new value
    _value = newValue;
    notifyListeners();
  }

  T? _previousValue;

  /// The previous value, if any.
  @override
  T? get previousValue => _previousValue;

  /// Calls a function with the current [value] and assigns the result as the
  /// new value.
  T update(T Function(T value) callback) => value = callback(value);

  /// [listener] will be invoked when the signal changes.
  @override
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  /// [listener] will no longer be invoked when the signal changes.
  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  /// Returns the number of listeners listening to this signal.
  int get listenerCount => _listeners.length;

  @protected
  void notifyListeners() {
    // We schedule a microtask to debounce multiple changes that can occur
    // all at once.
    if (_microtaskVersion == _version) {
      _microtaskVersion++;
      scheduleMicrotask(() {
        _version++;
        _microtaskVersion = _version;

        // Convert the Set to a List before executing each listener. This
        // prevents errors that can arise if a listener removes itself during
        // invocation
        _listeners.toList().forEach((VoidCallback listener) => listener());
      });
    }
  }

  /// The [select] function allows filtering unwanted rebuilds by reading only
  /// the properties that we care about.
  @override
  Signal<Selected> select<Selected>(
    Selected Function(T value) selector,
  ) {
    final signalSelector = SignalSelector<T, Selected>(
      signal: this,
      selector: selector,
    );
    // ignore: unnecessary_cast
    return signalSelector as Signal<Selected>;
  }

  @override
  void onDispose(VoidCallback cb) {
    _onDisposeCallbacks.add(cb);
  }

  @override
  bool get disposed => _disposed;

  @override
  void dispose() {
    // ignore if already disposed
    if (_disposed) return;
    _listeners.clear();
    _disposed = true;

    for (final cb in _onDisposeCallbacks) {
      cb();
    }
    _onDisposeCallbacks.clear();
  }

  @override
  String toString() =>
      '''Signal<$T>(value: $value, previousValue: $previousValue, options; $options)''';
}
