part of 'core.dart';

/// {@macro readsignal}
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
  factory ReadSignal(
    T initialValue, {
    /// {@macro SignalBase.name}
    String? name,

    /// {@macro SignalBase.equals}
    bool? equals,

    /// {@macro SignalBase.autoDispose}
    bool? autoDispose,

    /// {@macro SignalBase.trackInDevTools}
    bool? trackInDevTools,

    /// {@macro SignalBase.comparator}
    ValueComparator<T?> comparator = identical,
  }) {
    return ReadSignal._internal(
      initialValue: initialValue,
      name: name ?? ReactiveContext.main.nameFor('ReadSignal'),
      equals: equals ?? SolidartConfig.equals,
      autoDispose: autoDispose ?? SolidartConfig.autoDispose,
      trackInDevTools: trackInDevTools ?? SolidartConfig.devToolsEnabled,
      comparator: comparator,
    );
  }

  ReadSignal._internal({
    required T initialValue,
    required super.name,
    required this.equals,
    required this.autoDispose,
    required this.trackInDevTools,
    required this.comparator,
  })  : _value = initialValue,
        _hasValue = true {
    _notifySignalCreation();
  }

  ReadSignal._internalLazy({
    required super.name,
    required this.equals,
    required this.autoDispose,
    required this.trackInDevTools,
    required this.comparator,
  }) : _hasValue = false;

  /// {@macro SignalBase.equals}
  @override
  final bool equals;

  /// {@macro SignalBase.autoDispose}
  @override
  final bool autoDispose;

  /// {@macro SignalBase.trackInDevTools}
  @override
  final bool trackInDevTools;

  /// {@macro SignalBase.comparator}
  @override
  final ValueComparator<T?> comparator;

  // Tracks the internal value
  late T _value;

  @override
  bool get hasValue {
    _reportObserved();
    return _hasValue;
  }

  bool _hasValue = false;

  // Tracks the internal previous value
  T? _previousValue;

  // Whether or not there is a previous value
  bool _hasPreviousValue = false;

  /// All the observers
  final List<ObserveCallback<T>> _listeners = [];

  @override
  T get value {
    if (!_hasValue) {
      throw StateError(
        '''The signal named "$name" is lazy and has not been initialized yet, cannot access its value''',
      );
    }
    _reportObserved();
    return _value;
  }

  /// {@template set-signal-value}
  /// Sets the current signal value with [newValue].
  ///
  /// This operation may be skipped if the value is equal to the previous one,
  /// check [equals] and [comparator].
  /// {@endtemplate}
  void _setValue(T newValue) {
    final firstValue = !_hasValue;
    _hasValue = true;

    // skip if the value are equals
    if (!firstValue && _areEqual(_value, newValue)) {
      return;
    }

    // store the previous value
    if (!firstValue) _setPreviousValue(_value);

    // notify with the new value
    _value = newValue;
    _reportChanged();
    _notifyListeners();

    if (firstValue) {
      _notifySignalCreation();
    } else {
      _notifySignalUpdate();
    }
  }

  void _notifyListeners() {
    if (_listeners.isNotEmpty) {
      _context.untracked(() {
        for (final listener in _listeners.toList(growable: false)) {
          listener(_previousValue, _value);
        }
      });
    }
  }

  /// Indicates if the [oldValue] and the [newValue] are equal
  bool _areEqual(T? oldValue, T? newValue) {
    // skip if the value are equals
    if (equals) {
      return oldValue == newValue;
    }

    // return the [comparator] result
    return comparator(oldValue, newValue);
  }

  @override
  T call() => value;

  @override
  bool get hasPreviousValue {
    _reportObserved();
    return _hasPreviousValue;
  }

  /// The previous value, if any.
  @override
  T? get previousValue {
    _reportObserved();
    return _previousValue;
  }

  /// Sets the previous signal value to [value].
  void _setPreviousValue(T value) {
    _previousValue = value;
    _hasPreviousValue = true;
  }

  bool _disposed = false;

  // Keeps track of all the callbacks passed to [onDispose].
  // Used later to fire each callback when this signal is disposed.
  final _onDisposeCallbacks = <VoidCallback>[];

  /// Returns the number of listeners listening to this signal.
  @override
  int get listenerCount => _observers.length + _listeners.length;

  @override
  void dispose() {
    // ignore if already disposed
    if (_disposed) return;
    _disposed = true;

    _listeners.clear();

    for (final cb in _onDisposeCallbacks) {
      cb();
    }
    _onDisposeCallbacks.clear();
    _notifySignalDisposal();
    for (final o in _observers.toList()) {
      o._mayDispose();
    }
  }

  @override
  bool get disposed => _disposed;

  /// Observe the signal and trigger the [listener] every time the value changes
  @override
  DisposeObservation observe(
    ObserveCallback<T> listener, {
    bool fireImmediately = false,
  }) {
    if (fireImmediately == true) {
      listener(_previousValue, _value);
    }

    _listeners.add(listener);

    return () {
      _listeners.remove(listener);
      _mayDispose();
    };
  }

  @override
  void _mayDispose() {
    if (!autoDispose) return;

    bool mayDispose() =>
        _listeners.isEmpty && _observers.isEmpty && _disposable;

    if (!mayDispose()) return;

    _context.enqueueForUnobservation(this);
    if (mayDispose()) dispose();
  }

  @override
  void onDispose(VoidCallback cb) {
    _onDisposeCallbacks.add(cb);
  }

  /// Returns the future that completes when the [condition] evalutes to true.
  /// If the [condition] is already true, it completes immediately.
  FutureOr<T> until(bool Function(T value) condition) {
    if (condition(value)) return value;

    final completer = Completer<T>();
    Effect((dispose) {
      if (condition(value)) {
        dispose();
        completer.complete(value);
      }
    });
    return completer.future;
  }

  void _notifySignalCreation() {
    for (final obs in SolidartConfig.observers) {
      obs.didCreateSignal(this);
    }
    // coverage:ignore-start
    if (!trackInDevTools) return;
    _notifyDevToolsAboutSignal(this, eventType: DevToolsEventType.created);
    // coverage:ignore-end
  }

  void _notifySignalUpdate() {
    for (final obs in SolidartConfig.observers) {
      obs.didUpdateSignal(this);
    }
    // coverage:ignore-start
    if (!trackInDevTools) return;
    _notifyDevToolsAboutSignal(this, eventType: DevToolsEventType.updated);
    // coverage:ignore-end
  }

  void _notifySignalDisposal() {
    for (final obs in SolidartConfig.observers) {
      obs.didDisposeSignal(this);
    }
    // coverage:ignore-start
    if (!trackInDevTools) return;
    _notifyDevToolsAboutSignal(this, eventType: DevToolsEventType.disposed);
    // coverage:ignore-end
  }

  @override
  String toString() =>
      '''ReadSignal<$T>(value: $_value, previousValue: $_previousValue)''';
}
