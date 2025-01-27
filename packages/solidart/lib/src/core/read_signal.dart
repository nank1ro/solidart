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
class ReadSignal<T> implements SignalBase<T> {
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

    /// {@macro SignalBase.trackPreviousValue}
    bool? trackPreviousValue,
  }) {
    return ReadSignal._internal(
      initialValue: initialValue,
      name: name ?? ReactiveName.nameFor('ReadSignal'),
      equals: equals ?? SolidartConfig.equals,
      autoDispose: autoDispose ?? SolidartConfig.autoDispose,
      trackInDevTools: trackInDevTools ?? SolidartConfig.devToolsEnabled,
      trackPreviousValue:
          trackPreviousValue ?? SolidartConfig.trackPreviousValue,
      comparator: comparator,
    );
  }

  ReadSignal._internal({
    required T initialValue,
    required this.name,
    required this.equals,
    required this.autoDispose,
    required this.trackInDevTools,
    required this.comparator,
    required this.trackPreviousValue,
  }) : _hasValue = true {
    _internalSignal = _AlienSignal(Some(initialValue), parent: this);
    _untrackedValue = initialValue;
    _notifySignalCreation();
  }

  ReadSignal._internalLazy({
    required this.name,
    required this.equals,
    required this.autoDispose,
    required this.trackInDevTools,
    required this.comparator,
    required this.trackPreviousValue,
  }) : _hasValue = false {
    _internalSignal = _AlienSignal(None<T>(), parent: this);
  }

  /// {@macro SignalBase.name}
  @override
  final String name;

  /// {@macro SignalBase.equals}
  @override
  final bool equals;

  /// {@macro SignalBase.autoDispose}
  @override
  final bool autoDispose;

  /// {@macro SignalBase.trackInDevTools}
  @override
  final bool trackInDevTools;

  /// {@macro SignalBase.trackPreviousValue}
  @override
  final bool trackPreviousValue;

  /// {@macro SignalBase.comparator}
  @override
  final ValueComparator<T?> comparator;

  /// Tracks the internal value
  late final _AlienSignal<Option<T>> _internalSignal;

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

  T get _value {
    print('disposed $_disposed');
    if (_disposed) {
      reactiveSystem.pauseTracking();
      final v = _internalSignal().unwrap();
      reactiveSystem.resumeTracking();
      return v;
    }
    _reportObserved();
    final value = _internalSignal().unwrap();

    if (autoDispose) {
      _subs.clear();

      var link = _internalSignal.subs;
      for (; link != null; link = link.nextSub) {
        final sub = link.sub;
        _subs.add(sub);
      }
    }
    return value;
  }

  late T _untrackedValue;

  T? _untrackedPreviousValue;

  /// Returns the untracked previous value of the signal.
  T? get untrackedPreviousValue {
    return _untrackedPreviousValue;
  }

  /// Returns the value without triggering the reactive system.
  T get untrackedValue {
    if (!_hasValue) {
      throw StateError(
        '''The signal named "$name" is lazy and has not been initialized yet, cannot access its value''',
      );
    }
    // _reportObserved();
    return _untrackedValue;
  }

  set _value(T newValue) {
    _untrackedPreviousValue = _untrackedValue;
    _untrackedValue = newValue;
    _internalSignal.currentValue = Some(newValue);
    _reportChanged();
  }

  /// All the observers
  final List<ObserveCallback<T>> _listeners = [];

  @override
  T get value {
    if (!_hasValue) {
      throw StateError(
        '''The signal named "$name" is lazy and has not been initialized yet, cannot access its value''',
      );
    }
    return _value;
  }

  /// {@template set-signal-value}
  /// Sets the current signal value with [newValue].
  ///
  /// This operation may be skipped if the value is equal to the previous one,
  /// check [equals] and [comparator].
  /// {@endtemplate}
  T _setValue(T newValue) {
    final firstValue = !_hasValue;

    if (firstValue) {
      _untrackedValue = newValue;
      _hasValue = true;
    }

    // // skip if the values are equal
    if (!firstValue && _compare(_untrackedValue, newValue)) {
      return newValue;
    }

    // store the previous value
    if (!firstValue) _setPreviousValue(_untrackedValue);

    // notify with the new value
    _value = newValue;

    _notifyListeners();

    if (firstValue) {
      _notifySignalCreation();
    } else {
      _notifySignalUpdate();
    }
    return newValue;
  }

  void _notifyListeners() {
    if (_listeners.isNotEmpty) {
      for (final listener in _listeners.toList(growable: false)) {
        listener(_previousValue, _untrackedValue);
      }
    }
  }

  @override
  T call() => value;

  @override
  bool get hasPreviousValue {
    if (!trackPreviousValue) return false;
    // cause observation
    value;
    return _hasPreviousValue;
  }

  /// The previous value, if any.
  @override
  T? get previousValue {
    if (!trackPreviousValue) return null;
    // cause observation
    value;
    return _previousValue;
  }

  /// Sets the previous signal value to [value].
  void _setPreviousValue(T value) {
    if (!trackPreviousValue) return;
    _previousValue = value;
    _hasPreviousValue = true;
  }

  bool _disposed = false;

  // Keeps track of all the callbacks passed to [onDispose].
  // Used later to fire each callback when this signal is disposed.
  final _onDisposeCallbacks = <VoidCallback>[];

  /// Returns the number of listeners listening to this signal.
  @override
  int get listenerCount => _listeners.length;

  final _subs = <alien.Subscriber>{};

  @override
  void dispose() {
    // ignore if already disposed
    if (_disposed) return;
    _disposed = true;

    // This will dispose the signal to _disposed being true
    reactiveSystem.pauseTracking();
    _internalSignal();
    reactiveSystem.resumeTracking();

    for (final sub in _subs) {
      print('sub runtimeType ${sub.runtimeType}');
      if (sub is _AlienEffect) {
        if (sub.deps?.dep == _internalSignal) {
          sub.deps = null;
        }
        if (sub.depsTail?.dep == _internalSignal) {
          sub.depsTail = null;
        }

        sub.parent._mayDispose();
      }
      if (sub is _AlienComputed) {
        if (sub.deps?.dep == _internalSignal) {
          sub.deps = null;
        }
        if (sub.depsTail?.dep == _internalSignal) {
          sub.depsTail = null;
        }
        sub.parent._mayDispose();
      }
    }
    _subs.clear();

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
      _mayDispose();
    };
  }

  @override
  void _mayDispose() {
    print('may dispose $name');
    if (!autoDispose || _disposed) return;
    if (_internalSignal.subs == null) dispose();
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

  void _reportObserved() {
    if (reactiveSystem.activeSub != null) {
      reactiveSystem.link(_internalSignal, reactiveSystem.activeSub!);
    }
  }

  void _reportChanged() {
    if (_internalSignal.subs != null) {
      reactiveSystem.propagate(_internalSignal.subs);
      if (reactiveSystem.batchDepth == 0) {
        reactiveSystem.processEffectNotifications();
      }
    }
  }

  @override
  String toString() =>
      '''ReadSignal<$T>(value: $_value, previousValue: $_previousValue)''';

  /// Indicates if the [oldValue] and the [newValue] are equal
  @override
  bool _compare(T? oldValue, T? newValue) {
    // skip if the value are equals
    if (equals) {
      return oldValue == newValue;
    }

    // return the [comparator] result
    return comparator(oldValue, newValue);
  }
}
