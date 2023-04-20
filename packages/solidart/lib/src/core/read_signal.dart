import 'package:meta/meta.dart';
import 'package:solidart/solidart.dart';
import 'package:solidart/src/core/atom.dart';
import 'package:solidart/src/core/derivation.dart';
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
    T? previousValue,
    SignalOptions<T>? options,
  })  : options = options ?? SignalOptions<T>(),
        _previousValue = previousValue;

  final T _value;
  T? _previousValue;
  @internal
  final List<ObserveCallback<T>> listeners = [];

  @override
  T get value {
    context.enforceReadPolicy(this);
    reportObserved();
    return _value;
  }

  @override
  T call() => value;

  @override
  T? get previousValue {
    context.enforceReadPolicy(this);
    reportObserved();
    return _previousValue;
  }

  @override
  final SignalOptions<T> options;

  bool _disposed = false;

  // Keeps track of all the callbacks passed to [onDispose].
  // Used later to fire each callback when this signal is disposed.
  final _onDisposeCallbacks = <VoidCallback>[];

  /// Returns the number of listeners listening to this signal.
  @override
  int get listenerCount => observers.length;

  @override
  bool get disposed => _disposed;

  @override
  void dispose() {
    // ignore if already disposed
    if (_disposed) return;
    _disposed = true;

    // observers.toList().forEach(removeObserver);
    listeners.clear();

    for (final cb in _onDisposeCallbacks) {
      cb();
    }
    _onDisposeCallbacks.clear();
  }

  /// Observe the signal and trigger the [listener] every time the value changes
  Dispose observe(ObserveCallback<T> listener, {bool fireImmediately = false}) {
    if (fireImmediately == true) {
      listener(_previousValue, _value);
    }

    listeners.add(listener);

    return () => listeners.remove(listener);
  }

  @override
  void onDispose(VoidCallback cb) {
    _onDisposeCallbacks.add(cb);
  }

  @override
  String toString() =>
      '''ReadSignal<$T>(value: $value, previousValue: $previousValue, options; $options)''';
}
