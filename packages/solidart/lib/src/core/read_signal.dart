part of 'core.dart';

/// {@macro readsignal}
abstract class ReadSignal<T> extends SignalBase<T> {
  /// {@macro readsignal}
  ReadSignal({
    required super.name,
    super.comparator,
    super.equals,
    super.autoDispose,
    super.trackInDevTools,
    super.trackPreviousValue,
  });
}

/// {@template readsignal}
/// A read-only [Signal].
///
/// When you don't need to expose the setter of a [Signal],
/// you should consider transforming it in a [ReadSignal]
/// using the `toReadSignal` method.
///
/// All derived-signals are [ReadableSignal]s because they depend
/// on the value of a [Signal].
/// {@endtemplate}
class ReadableSignal<T> implements ReadSignal<T> {
  /// {@macro readsignal}
  ReadableSignal(
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
    this.comparator = identical,

    /// {@macro SignalBase.trackPreviousValue}
    bool? trackPreviousValue,
  })  : _hasValue = true,
        trackInDevTools = trackInDevTools ?? SolidartConfig.devToolsEnabled,
        autoDispose = autoDispose ?? SolidartConfig.autoDispose,
        equals = equals ?? SolidartConfig.equals,
        name = name ?? ReactiveName.nameFor('ReadSignal'),
        trackPreviousValue =
            trackPreviousValue ?? SolidartConfig.trackPreviousValue {
    _internalSignal = _AlienSignal(this, Some(initialValue));
    _untrackedValue = initialValue;
    _notifySignalCreation();
  }

  /// {@macro readsignal}
  ReadableSignal.lazy({
    /// {@macro SignalBase.name}
    String? name,

    /// {@macro SignalBase.equals}
    bool? equals,

    /// {@macro SignalBase.autoDispose}
    bool? autoDispose,

    /// {@macro SignalBase.trackInDevTools}
    bool? trackInDevTools,

    /// {@macro SignalBase.comparator}
    this.comparator = identical,

    /// {@macro SignalBase.trackPreviousValue}
    bool? trackPreviousValue,
  })  : _hasValue = false,
        trackInDevTools = trackInDevTools ?? SolidartConfig.devToolsEnabled,
        autoDispose = autoDispose ?? SolidartConfig.autoDispose,
        equals = equals ?? SolidartConfig.equals,
        // coverage:ignore-start
        name = name ?? ReactiveName.nameFor('ReadSignal'),
        // coverage:ignore-end
        trackPreviousValue =
            trackPreviousValue ?? SolidartConfig.trackPreviousValue {
    _internalSignal = _AlienSignal(this, None<T>());
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
  late final _AlienSignal<T> _internalSignal;

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
    if (_disposed) {
      return untracked(
        () => reactiveSystem.getSignalValue(_internalSignal).unwrap(),
      );
    }
    _reportObserved();
    final value = reactiveSystem.getSignalValue(_internalSignal).unwrap();

    if (autoDispose) {
      _subs.clear();

      var link = _internalSignal.subs;
      for (; link != null; link = link.nextSub) {
        _subs.add(link.sub);
      }
    }
    return value;
  }

  late T _untrackedValue;

  T? _untrackedPreviousValue;

  /// Returns the untracked previous value of the signal.
  @override
  T? get untrackedPreviousValue {
    return _untrackedPreviousValue;
  }

  /// Returns the value without triggering the reactive system.
  @override
  T get untrackedValue {
    if (!_hasValue) {
      throw StateError(
        '''The signal named "$name" is lazy and has not been initialized yet, cannot access its value''',
      );
    }
    return _untrackedValue;
  }

  set _value(T newValue) {
    _untrackedPreviousValue = _untrackedValue;
    _untrackedValue = newValue;
    reactiveSystem.setSignalValue(_internalSignal, Some(newValue));
  }

  @override
  T get value {
    if (!_hasValue) {
      throw StateError(
        '''The signal named "$name" is lazy and has not been initialized yet, cannot access its value''',
      );
    }
    return _value;
  }

  @override
  T call() {
    return value;
  }

  /// {@template set-signal-value}
  /// Sets the current signal value with [newValue].
  ///
  /// This operation may be skipped if the value is equal to the previous one,
  /// check [equals] and [comparator].
  /// {@endtemplate}
  @protected
  T setValue(T newValue) {
    final firstValue = !_hasValue;

    if (firstValue) {
      _untrackedValue = newValue;
      _hasValue = true;
    }

    // skip if the values are equal
    if (!firstValue && _compare(_untrackedValue, newValue)) {
      return newValue;
    }

    // store the previous value
    if (!firstValue) _setPreviousValue(_untrackedValue);

    // notify with the new value
    _value = newValue;

    if (firstValue) {
      _notifySignalCreation();
    } else {
      _notifySignalUpdate();
    }
    return newValue;
  }

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
  int get listenerCount => _subs.length;

  final _subs = <alien.ReactiveNode>{};

  @override
  void dispose() {
    // ignore if already disposed
    if (_disposed) return;
    _disposed = true;

    // This will dispose the signal
    untracked(() {
      reactiveSystem.getSignalValue(_internalSignal);
    });

    if (SolidartConfig.autoDispose) {
      for (final sub in _subs) {
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
          // coverage:ignore-start
          if (sub.deps?.dep == _internalSignal) {
            sub.deps = null;
          }
          if (sub.depsTail?.dep == _internalSignal) {
            sub.depsTail = null;
          }
          // coverage:ignore-end
          sub.parent._mayDispose();
        }
      }
      _subs.clear();
    }

    for (final cb in _onDisposeCallbacks) {
      cb();
    }
    _onDisposeCallbacks.clear();
    _notifySignalDisposal();
  }

  @override
  bool get disposed => _disposed;

  @override
  void _mayDispose() {
    if (!autoDispose || _disposed) return;
    if (_internalSignal.subs == null) dispose();
  }

  @override
  void onDispose(VoidCallback cb) {
    _onDisposeCallbacks.add(cb);
  }

  /// Returns the future that completes when the [condition] evalutes to true.
  /// If the [condition] is already true, it completes immediately.
  ///
  /// The [timeout] parameter specifies the maximum time to wait for the
  /// condition to be met. If provided and the timeout is reached before the
  /// condition is met, the future will complete with a [TimeoutException].
  FutureOr<T> until(
    bool Function(T value) condition, {
    Duration? timeout,
  }) {
    if (condition(value)) return value;

    final completer = Completer<T>();
    Timer? timer;
    late final Effect effect;

    void dispose() {
      effect.dispose();
      timer?.cancel();
    }

    effect = Effect(
      () {
        if (condition(value)) {
          dispose();
          completer.complete(value);
        }
      },
      autoDispose: false,
    );

    // Start timeout timer if specified
    if (timeout != null) {
      timer = Timer(timeout, () {
        if (!completer.isCompleted) {
          dispose();
          completer.completeError(TimeoutException(null, timeout));
        }
      });
    }

    return completer.future;
  }

  void _reportObserved() {
    if (reactiveSystem.activeSub != null) {
      reactiveSystem.link(_internalSignal, reactiveSystem.activeSub!);
    }
  }

  /// Forces a change notification even when the value
  /// hasn't substantially changed.
  ///
  /// This should only be used when you need to force
  /// trigger reactions despite no
  /// actual value change. For normal value updates,
  // ignore: comment_references
  /// use [reactiveSystem.setSignalValue] instead.
  void _reportChanged() {
    _internalSignal.forceDirty = true;
    _internalSignal.flags = 17 /* Mutable | Dirty */;
    final subs = _internalSignal.subs;
    if (subs != null) {
      // coverage:ignore-start
      reactiveSystem.propagate(subs);
      if (reactiveSystem.batchDepth == 0) {
        reactiveSystem.flush();
      }
      // coverage:ignore-end
    }
  }

  /// Manually triggers an update check for this signal.
  ///
  /// When [force] is true, bypasses normal dirty checking and forces
  /// a re-evaluation of all dependent computations and effects.
  ///
  /// Returns `true` if the signal's value changed and subscribers were
  /// notified, `false` otherwise.
  ///
  /// Use this sparingly—prefer normal value updates via `value =` or
  /// `updateValue()`. This is primarily useful when integrating with
  /// external systems that need explicit control over the reactive cycle.
  bool triggerUpdate({bool force = false}) {
    if (force) _internalSignal.forceDirty = true;
    return _internalSignal.update();
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
