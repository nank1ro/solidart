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
class ReadSignal<T> extends Atom
    with alien.Dependency
    implements SignalBase<T> {
  /// {@macro readsignal}
  factory ReadSignal(
    T initialValue, {
    SignalOptions<T>? options,
  }) {
    final name = options?.name ?? 'ReadSignal<$T>';
    final effectiveOptions =
        (options ?? SignalOptions<T>(name: name)).copyWith(name: name);
    return ReadSignal._internal(
      initialValue: initialValue,
      options: effectiveOptions,
      name: name,
    );
  }

  ReadSignal._internal({
    required T initialValue,
    required super.name,
    required this.options,
  }) : _value = initialValue {
    _notifySignalCreation();
  }

  // Tracks the internal value
  T _value;

  // Tracks the internal previous value
  T? _previousValue;

  // Whether or not there is a previous value
  bool _hasPreviousValue = false;

  /// All the observers
  final List<ObserveCallback<T>> _listeners = [];

  @override
  T get value {
    if (!_disposed) _linkDep();
    _notifyListeners();
    return _value;
  }

  void _linkDep() {
    if (system.activeSub != null) {
      system.link(this, system.activeSub!);
    }
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
    _setPreviousValue(_value);
    _value = newValue;
    if (subs != null) {
      system.propagate(subs);
      if (system.batchDepth == 0) {
        system.processEffectNotifications();
      }
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

  void _notifyListeners() {
    if (_listeners.isNotEmpty) {
      for (final listener in _listeners) {
        listener(_previousValue, _value);
      }
    }
  }

  @override
  T call() => value;

  @override
  bool get hasPreviousValue {
    if (!_disposed) _linkDep();
    return _hasPreviousValue;
  }

  /// The previous value, if any.
  @override
  T? get previousValue {
    if (!_disposed) _linkDep();
    return _previousValue;
  }

  /// Sets the previous signal value to [value].
  void _setPreviousValue(T value) {
    _previousValue = value;
    _hasPreviousValue = true;
  }

  @override
  final SignalOptions<T> options;

  bool _disposed = false;

  // Keeps track of all the callbacks passed to [onDispose].
  // Used later to fire each callback when this signal is disposed.
  final _onDisposeCallbacks = <VoidCallback>[];

  /// Returns the number of listeners listening to this signal.
  @override
  int listenerCount = 0;

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
    };
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
  // coverage:ignore-end

  void _notifySignalCreation() {
    for (final obs in SolidartConfig.observers) {
      obs.didCreateSignal(this);
    }
    _notifyDevToolsAboutSignal(this, eventType: DevToolsEventType.created);
  }

  void _notifySignalUpdate() {
    for (final obs in SolidartConfig.observers) {
      obs.didUpdateSignal(this);
    }
    _notifyDevToolsAboutSignal(this, eventType: DevToolsEventType.updated);
  }

  void _notifySignalDisposal() {
    for (final obs in SolidartConfig.observers) {
      obs.didDisposeSignal(this);
    }
    _notifyDevToolsAboutSignal(this, eventType: DevToolsEventType.disposed);
  }

  @override
  String toString() =>
      '''ReadSignal<$T>(value: $_value, previousValue: $_previousValue, options: $options)''';
}
