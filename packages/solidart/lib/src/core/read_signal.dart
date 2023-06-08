import 'dart:async';

import 'package:meta/meta.dart';
import 'package:solidart/src/core/atom.dart';
import 'package:solidart/src/core/effect.dart';
import 'package:solidart/src/core/signal.dart';
import 'package:solidart/src/core/signal_base.dart';
import 'package:solidart/src/core/signal_options.dart';
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
/// using the `toReadSignal` method.
///
/// All derived-signals are [ReadSignal]s because they depend
/// on the value of a [Signal].
/// {@endtemplate}
class ReadSignal<T> extends Atom implements SignalBase<T> {
  /// {@macro readsignal}
  ReadSignal(
    this._value, {
    SignalOptions<T>? options,
  }) : options = options ?? SignalOptions<T>();

  final T _value;

  /// All the observers
  @internal
  final List<ObserveCallback<T>> listeners = [];

  @override
  T get value {
    reportObserved();
    return _value;
  }

  @override
  T call() => value;

  // coverage:ignore-start
  @override
  T? get previousValue {
    // no-op
    return null;
  }
  // coverage:ignore-end

  @override
  final SignalOptions<T> options;

  bool _disposed = false;

  // Keeps track of all the callbacks passed to [onDispose].
  // Used later to fire each callback when this signal is disposed.
  final _onDisposeCallbacks = <VoidCallback>[];

  /// Returns the number of listeners listening to this signal.
  @override
  int get listenerCount => observers.length + listeners.length;

  @override
  bool get disposed => _disposed;

  @override
  void dispose() {
    // ignore if already disposed
    if (_disposed) return;
    _disposed = true;

    listeners.clear();

    for (final cb in _onDisposeCallbacks) {
      cb();
    }
    _onDisposeCallbacks.clear();
  }

  /// Observe the signal and trigger the [listener] every time the value changes
  // coverage:ignore-start
  @override
  DisposeEffect observe(
    ObserveCallback<T> listener, {
    bool fireImmediately = false,
  }) {
    // no-op
    return () {};
  }
  // coverage:ignore-end

  @override
  void onDispose(VoidCallback cb) {
    _onDisposeCallbacks.add(cb);
  }

  /// Returns the future that completes when the [condition] evalutes to true.
  /// If the [condition] is already true, it completes immediately.
  @experimental
  FutureOr<T> firstWhere(bool Function(T value) condition) {
    if (condition(value)) return value;

    final completer = Completer<T>();
    createEffect((dispose) {
      if (condition(value)) {
        dispose();
        completer.complete(value);
      }
    });
    return completer.future;
  }

  /// Returns the future that completes when the [condition] evalutes to true.
  /// If the [condition] is already true, it completes immediately.
  @experimental
  @Deprecated('Use firstWhere instead')
  FutureOr<T> until(bool Function(T value) condition) {
    return firstWhere(condition);
  }

  @override
  String toString() =>
      '''ReadSignal<$T>(value: $value, previousValue: $previousValue, options; $options)''';
}
