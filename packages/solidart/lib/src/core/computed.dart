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
    String? name,

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
  }) : super(name: name ?? ReactiveName.nameFor('Computed')) {
    var runnedOnce = false;
    _internalComputed = _AlienComputed(
      this,
      (previousValue) {
        if (trackPreviousValue && previousValue is T) {
          _hasPreviousValue = true;
          _untrackedPreviousValue = _previousValue = previousValue;
        }

        try {
          _untrackedValue = selector();

          if (runnedOnce) {
            _notifySignalUpdate();
          } else {
            runnedOnce = true;
          }
          return _untrackedValue;
        } catch (e, s) {
          throw SolidartCaughtException(e, stackTrace: s);
        }
      },
    );

    _notifySignalCreation();
  }

  /// The selector applied
  final T Function() selector;

  late final _AlienComputed<T> _internalComputed;

  bool _disposed = false;

  late T _untrackedValue;

  T? _previousValue;

  T? _untrackedPreviousValue;

  // Whether or not there is a previous value
  bool _hasPreviousValue = false;

  // Keeps track of all the callbacks passed to [onDispose].
  // Used later to fire each callback when this signal is disposed.
  final _onDisposeCallbacks = <VoidCallback>[];

  // A computed signal is always initialized
  @override
  bool get hasValue => true;

  final _deps = <alien.ReactiveNode>{};

  @override
  void dispose() {
    if (_disposed) return;

    _internalComputed.dispose();
    _disposed = true;
    for (final dep in _deps) {
      if (dep is _AlienSignal) dep.parent._mayDispose();
      if (dep is _AlienComputed) dep.parent._mayDispose();
    }

    _deps.clear();

    for (final cb in _onDisposeCallbacks) {
      cb();
    }
    _onDisposeCallbacks.clear();
    _notifySignalDisposal();
  }

  @override
  T get value {
    if (_disposed) {
      return _untrackedValue;
    }

    final value = reactiveSystem.getComputedValue(_internalComputed);
    if (autoDispose) {
      Future.microtask(_mayDispose);
    }

    return value;
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
    if (!disposed) value;
    return _previousValue;
  }

  /// Returns the untracked value of the computed.
  @override
  T get untrackedValue {
    return _untrackedValue;
  }

  /// Returns the untracked previous value of the computed.
  @override
  T? get untrackedPreviousValue {
    return _untrackedPreviousValue;
  }

  @override
  void _mayDispose() {
    if (_disposed) return;
    if (_internalComputed.deps == null && _internalComputed.subs == null) {
      dispose();
    } else {
      _deps.clear();

      var link = _internalComputed.deps;
      for (; link != null; link = link.nextDep) {
        final dep = link.dep;
        _deps.add(dep);
      }
    }
  }

  @override
  bool get disposed => _disposed;

  @override
  bool get hasPreviousValue {
    if (!trackPreviousValue) return false;
    // cause observation
    value;
    return _hasPreviousValue;
  }

  // coverage:ignore-start
  @override
  int get listenerCount => _deps.length;
  // coverage:ignore-end

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

  @override
  String toString() {
    value;
    return '''Computed<$T>(value: $untrackedValue, previousValue: $untrackedPreviousValue)''';
  }
}
