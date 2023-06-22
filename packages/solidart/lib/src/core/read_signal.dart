part of 'core.dart';

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
    T initialValue, {
    SignalOptions<T>? options,
  })  : _value = initialValue,
        options = options ?? SignalOptions<T>();

  // Tracks the internal value
  T _value;

  // Tracks the internal previous value
  T? _previousValue;

  // Whether or not there is a previous value
  bool _hasPreviousValue = false;

  /// All the observers
  @internal
  final List<ObserveCallback<T>> listeners = [];

  @override
  T get value {
    _reportObserved();
    return _value;
  }

  /// {@template set-signal-value}
  /// Sets the current signal value with [newValue].
  ///
  /// This operation may be skipped if the value is equal to the previous one,
  /// check [SignalOptions.equals] and [SignalOptions.comparator].
  /// {@endtemplate}
  void _setValue(T newValue) {
    // skip if the value are equals
    if (_areEqual(_value, newValue)) {
      return;
    }

    // store the previous value
    _previousValue = _value;
    _hasPreviousValue = true;

    // notify with the new value
    _value = newValue;
    _reportChanged();
    _notifyListeners();
  }

  void _notifyListeners() {
    if (listeners.isNotEmpty) {
      context.untracked(() {
        for (final listener in listeners.toList(growable: false)) {
          listener(_previousValue, _value);
        }
      });
    }
  }

  /// Indicates if the [oldValue] and the [newValue] are equal
  bool _areEqual(T? oldValue, T? newValue) {
    // skip if the value are equals
    if (options.equals) {
      return oldValue == newValue;
    }

    // return the [comparator] result
    return options.comparator!(oldValue, newValue);
  }

  @override
  T call() => value;

  @override
  bool get hasPreviousValue => _hasPreviousValue;

  /// The previous value, if any.
  @override
  T? get previousValue {
    _reportObserved();
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
  int get listenerCount => _observers.length + listeners.length;

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
  @override
  DisposeObservation observe(
    ObserveCallback<T> listener, {
    bool fireImmediately = false,
  }) {
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
