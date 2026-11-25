part of 'core.dart';

/// {@template computed}
/// A special Signal that notifies only whenever the selected
/// values change.
///
/// You may want to subscribe only to sub-field of a `Signal` value or to
/// combine multiple signal values.
/// ```dart
/// // first name signal
/// final firstName = Signal('Josh');
///
/// // last name signal
/// final lastName = Signal('Brown');
///
/// // derived signal, updates automatically when firstName or lastName change
/// final fullName = Computed(() => '${firstName()} ${lastName()}');
///
/// print(fullName()); // prints Josh Brown
///
/// // just update the name, the effect above doesn't run because the age has not changed
/// user.update((value) => value.copyWith(name: 'new-name'));
///
/// // just update the age, the effect above prints
/// user.update((value) => value.copyWith(age: 21));
/// ```
///
/// A derived signal is not of type `Signal` but is a `ReadSignal`.
/// The difference with a normal `Signal` is that a `ReadSignal` doesn't have a
/// value setter, in other words it's a __read-only__ signal.
///
/// You can also use derived signals in other ways, like here:
/// ```dart
/// final counter = Signal(0);
/// final doubleCounter = Computed(() => counter() * 2);
/// ```
///
/// Every time the `counter` signal changes, the doubleCounter updates with the
/// new doubled `counter` value.
///
/// You can also transform the value type like:
/// ```dart
/// final counter = Signal(0); // counter contains the value type `int`
/// final isGreaterThan5 = Computed(() => counter() > 5); // isGreaterThan5 contains the value type `bool`
/// ```
///
/// `isGreaterThan5` will update only when the `counter` value becomes lower/greater than `5`.
/// - If the `counter` value is `0`, `isGreaterThan5` is equal to `false`.
/// - If you update the value to `1`, `isGreaterThan5` doesn't emit a new
/// value, but still contains `false`.
/// - If you update the value to `6`, `isGreaterThan5` emits a new `true` value.
/// {@endtemplate}
class Computed<T> extends ReadSignal<T> {
  /// {@macro computed}
  Computed(
    this.selector, {

    /// {@macro SignalBase.name}
    super.name,

    /// {@macro SignalBase.equals}
    super.equals,

    /// {@macro SignalBase.autoDispose}
    super.autoDispose,

    /// {@macro SignalBase.trackInDevTools}
    super.trackInDevTools,

    /// {@macro SignalBase.comparator}
    super.comparator = identical,

    /// {@macro SignalBase.trackPreviousValue}
    super.trackPreviousValue,
  }) {
    _internalComputed = _AlienComputed(
      this,
      (previousValue) {
        // Only an earlier successful evaluation is a previous value. For a
        // nullable T, the null passed before the first one is not.
        if (trackPreviousValue && _initialized) {
          _hasPreviousValue = true;
          _previousValue = previousValue as T;
        }

        _evaluating = true;
        try {
          final T value;
          try {
            value = selector();
          } catch (e, s) {
            throw _error = SolidartCaughtException(e, stackTrace: s);
          }
          _untrackedValue = value;
          _error = null;
          _initialized = true;
          _equalsPrevious = false;
          // The first evaluation from get() has nothing to compare with.
          if (_internalComputed.updating) {
            try {
              // Runs while this computed is the active subscriber, so
              // signals read by the comparator become dependencies.
              _equalsPrevious = _compare(previousValue, value);
            } catch (e, s) {
              // Not a selector error: keep the value as a change and report
              // the error to the zone, untracked, instead of throwing it.
              untracked(() => Zone.current.handleUncaughtError(e, s));
            }
          }
          _notifyPending = true;
          return value;
        } finally {
          _evaluating = false;
        }
      },
    );

    _notifySignalCreation();
  }

  /// The selector applied
  final T Function() selector;

  late final _AlienComputed<T> _internalComputed;

  bool _disposed = false;

  bool _initialized = false;

  // The error of the latest evaluation, or null if it succeeded.
  SolidartCaughtException? _error;

  bool get _hasError => _error != null;

  // Whether the latest successful value equals the one before it.
  bool _equalsPrevious = false;

  // Whether the selector or the comparator is running. Reads of the stored
  // state then return it without evaluating again.
  bool _evaluating = false;

  // Whether a successful evaluation still has to notify, after it is
  // committed.
  bool _notifyPending = false;

  bool _notifiedOnce = false;

  late T _untrackedValue;

  T? _previousValue;

  // Whether or not there is a previous value
  bool _hasPreviousValue = false;

  // Keeps track of all the callbacks passed to [onDispose].
  // Used later to fire each callback when this signal is disposed.
  final _onDisposeCallbacks = <VoidCallback>[];

  // A computed always reports hasValue == true, but the underlying value is
  // lazy: the selector runs on first access. Calling hasValue triggers that
  // first computation.
  @override
  bool get hasValue {
    if (!_disposed && !_initialized) value;
    return true;
  }

  @override
  bool get untrackedHasValue => true;

  final _deps = <_SavedInput>{};

  @override
  void dispose() {
    if (_disposed) return;
    // Set first: unlinking a subscriber can offer this computed disposal.
    _disposed = true;
    // Keep the reads of onDispose callbacks out of the running effect.
    untracked(_dispose);
  }

  void _dispose() {
    // Like Effect.dispose, offer the inputs whatever this computed's own
    // autoDispose is. Only an autoDispose computed records [_deps].
    final dependencies = {..._inputs, for (final input in _deps) ?input.node};
    _deps.clear();
    _internalComputed.saved.node = null;
    // Like Effect.dispose: the auto-disposal of the dependencies waits for the
    // running batch, flush or evaluation, and yields to queued effects. The
    // batch also holds back the dependencies of the child effects, so the
    // onDispose callbacks and the observers can subscribe to them first.
    // Every step runs in [errors], so the batch always ends.
    reactiveSystem.startBatch();
    final errors = _FirstError()..run(_internalComputed.dispose);
    reactiveSystem._pendingDisposals.addAll(dependencies);
    errors
      ..runAll(_onDisposeCallbacks)
      ..run(_listeners.dispose)
      ..run(() => _notifySignalDisposal(errors))
      ..runAll(_onDisposeCallbacks)
      ..run(reactiveSystem.endBatch)
      ..rethrowIfAny();
  }

  @override
  T get value {
    if (_disposed) {
      return untrackedValue;
    }
    // A read while the selector or comparator runs: return the stored value
    // or candidate without evaluating again.
    if (_evaluating && _initialized) {
      _linkActiveSubscriber();
      return _untrackedValue;
    }

    final T value;
    try {
      value = reactiveSystem.getComputedValue(_internalComputed);
    } on Object {
      // A failed evaluation also reads inputs: record them so dispose()
      // reaches them. Do not dispose here, so later reads rethrow the error.
      _recordInputs(merge: true);
      rethrow;
    }
    // The first evaluation runs from get(), without didUpdate().
    _notifyEvaluated();
    if (autoDispose) {
      _mayDispose();
    }

    return value;
  }

  // Links another reader, such as an effect created by the selector, so it
  // reruns on later changes. The computed's own reads stay unlinked.
  void _linkActiveSubscriber() {
    if (disposed) return;
    final sub = reactiveSystem.activeSub;
    if (sub != null && !identical(sub, _internalComputed)) {
      reactiveSystem.link(_internalComputed, sub);
    }
  }

  // Notifies about a successful evaluation once alien_signals committed it.
  void _notifyEvaluated() {
    if (!_notifyPending) return;
    _notifyPending = false;
    if (_notifiedOnce) {
      // Observers must not subscribe the effect or computed that reads this.
      untracked(_notifySignalUpdate);
    } else {
      _notifiedOnce = true;
      // The creation event had no value yet: send the first one.
      _notifyDevToolsAboutSignal(this, eventType: DevToolsEventType.updated);
    }
  }

  @override
  T call() {
    return value;
  }

  /// Returns the previous value of the computed.
  @override
  T? get previousValue {
    if (!trackPreviousValue) return null;
    // cause observation
    if (_evaluating) {
      _linkActiveSubscriber();
    } else if (!disposed) {
      value;
    }
    return _previousValue;
  }

  /// Returns the untracked value of the computed.
  @override
  T get untrackedValue {
    assert(
      _initialized,
      'Computed($name) has not been initialized yet. '
      'Access "value" or "hasValue" first to trigger computation.',
    );
    // Re-evaluate if stale, without registering as a dependency.
    if (!_disposed && !_evaluating) {
      untracked(() => value);
    }
    return _untrackedValue;
  }

  /// Returns the untracked previous value of the computed.
  @override
  T? get untrackedPreviousValue => untracked(() => previousValue);

  // The real inputs, including child effects and scopes. Skips internal
  // nodes, such as the retry dependency that alien_signals links after a
  // failed evaluation.
  List<alien_system.ReactiveNode> get _inputs => [
    for (var link = _internalComputed.deps; link != null; link = link.nextDep)
      if (link.dep
          case alien.SignalNode() ||
              alien.ComputedNode() ||
              alien.LinkedEffect() ||
              alien.EffectScopeNode())
        link.dep,
  ];

  /// Records the current inputs. A failed evaluation merges them into the
  /// earlier ones, because the failure may have unlinked inputs that
  /// dispose() must still reach.
  void _recordInputs({
    List<alien_system.ReactiveNode>? inputs,
    bool merge = false,
  }) {
    if (!merge) _deps.clear();
    _deps.addAll([
      for (final input in inputs ?? _inputs)
        if (input
            case _AlienSignal(:final saved) || _AlienComputed(:final saved))
          saved,
    ]);
  }

  @override
  void _mayDispose() {
    if (_disposed || !autoDispose) return;
    final inputs = _inputs;
    if (inputs.isEmpty && _internalComputed.subs == null) {
      dispose();
    } else {
      _recordInputs(inputs: inputs);
    }
  }

  @override
  bool get disposed => _disposed;

  @override
  bool get hasPreviousValue {
    if (!trackPreviousValue) return false;
    // cause observation
    if (_evaluating) {
      _linkActiveSubscriber();
    } else {
      value;
    }
    return _hasPreviousValue;
  }

  @override
  bool get untrackedHasPreviousValue => trackPreviousValue && _hasPreviousValue;

  @override
  int get listenerCount => _internalComputed.subscriberCount;

  late final _listeners = _SignalListeners<T>(this);

  /// Registers [listener].
  ///
  /// Registration computes the value if needed, like reading [value]. A
  /// selector error is thrown to the caller, as it is to any code that
  /// triggers the computation. [Listenable.onError] only receives errors
  /// thrown by listeners.
  @override
  void addListener(VoidCallback listener) => _listeners.add(listener);

  @override
  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  @override
  void onDispose(VoidCallback cb) {
    _onDisposeCallbacks.add(cb);
  }

  // coverage:ignore-start
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
  // coverage:ignore-end

  /// Manually runs the computed to update its value.
  /// This is usually not necessary, as the computed will automatically
  /// update when its dependencies change.
  /// However, in some cases, you may want to force an update.
  void run() {
    if (_disposed) return;
    // The error of this run. The cleanup that ends the evaluation, a
    // subscriber notified below, or an observer can run this computed again
    // and replace [_error].
    SolidartCaughtException? error;
    // Whether this run must notify the subscribers of its change.
    var notify = false;
    // A cleanup error after a committed change, rethrown after the
    // subscribers are notified of the change.
    final errors = _FirstError();
    try {
      reactiveSystem._evaluate(() {
        (changed: _, :notify, :error) = _internalComputed.update();
      });
    } catch (e, s) {
      // The selector error has priority over an error from the cleanup that
      // ends the evaluation.
      if (error != null) {
        Zone.current.handleUncaughtError(e, s);
      } else if (notify) {
        errors.run(() => Error.throwWithStackTrace(e, s));
      } else {
        rethrow;
      }
    } finally {
      // Like a read: record the inputs so dispose() reaches them.
      _recordInputs(merge: error != null);
    }
    if (notify) {
      if (error != null) {
        // The caller must still get the selector error: a notification
        // error goes to the zone.
        try {
          reactiveSystem.notifySubscribers(_internalComputed);
        } catch (notifyError, notifyStackTrace) {
          Zone.current.handleUncaughtError(notifyError, notifyStackTrace);
        }
      } else {
        errors
          ..run(() => reactiveSystem.notifySubscribers(_internalComputed))
          ..rethrowIfAny();
      }
    }
    final runError = error;
    if (runError != null) {
      Error.throwWithStackTrace(runError, runError.stackTrace!);
    }
  }

  @override
  final _id = ReactiveName.nameFor('Computed');

  @override
  String toString() {
    value;
    return '''Computed<$T>(value: $untrackedValue, previousValue: $untrackedPreviousValue)''';
  }
}
