import 'dart:async';

import 'package:meta/meta.dart';
import 'package:solidart/src/core/signal.dart';
import 'package:solidart/src/core/signal_base.dart';
import 'package:solidart/src/core/signal_options.dart';
import 'package:solidart/src/core/signal_selector.dart';
import 'package:solidart/src/utils.dart';

/// {@macro readsignal}
@Deprecated(
  '''Use ReadSignal instead. It will be removed in future releases.''',
)
typedef ReadableSignal<T> = ReadSignal<T>;

/// {@template readsignal}
/// A read-only [Signal].
///
/// When you don't need to expose the setter of a [Signal],
/// you should consider transforming it in a [ReadSignal]
/// using the `readable` method.
///
/// All derived-signals are [ReadSignal]s because they depend
/// on the value of a [Signal].
/// {@endtemplate}
class ReadSignal<T> implements SignalBase<T> {
  /// {@macro readsignal}
  ReadSignal(
    this._value, {
    T? previousValue,
    SignalOptions<T>? options,
  })  : options = options ?? SignalOptions<T>(),
        _previousValue = previousValue;

  final T _value;
  final T? _previousValue;

  @override
  T get value => _value;

  @override
  T call() => value;

  @override
  T? get previousValue => _previousValue;

  @override
  final SignalOptions<T> options;

  bool _disposed = false;

  final _listeners = <VoidCallback>{};
  int _version = 0;
  int _microtaskVersion = 0;
  // Keeps track of all the callbacks passed to [onDispose].
  // Used later to fire each callback when this signal is disposed.
  final _onDisposeCallbacks = <VoidCallback>[];

  /// The [select] function allows filtering unwanted rebuilds by reading only
  /// the properties that we care about.
  ReadSignal<Selected> select<Selected>(
    Selected Function(T value) selector, {
    SignalOptions<Selected>? options,
  }) {
    final signalSelector = SignalSelector<T, Selected>(
      signal: this as Signal<T>,
      selector: selector,
      options: options,
    );
    return signalSelector.toReadSignal();
  }

  @override
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  /// Returns the number of listeners listening to this signal.
  @override
  int get listenerCount => _listeners.length;

  /// Notifies every listener. Never use this method.
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
  bool get disposed => _disposed;

  @override
  void onDispose(VoidCallback cb) {
    _onDisposeCallbacks.add(cb);
  }

  @override
  String toString() =>
      '''ReadSignal<$T>(value: $value, previousValue: $previousValue, options; $options)''';
}
