part of 'core.dart';

/// {@macro computed}
Computed<T> createComputed<T>(
  T Function() selector, {
  SignalOptions<T>? options,
}) =>
    Computed<T>(selector, options: options);

/// {@template computed}
/// A special Signal that notifies only whenever the selected
/// values change.
///
/// You may want to subscribe only to sub-field of a `Signal` value or to
/// combine multiple signal values.
/// ```dart
/// // first name signal
/// final firstName = createSignal('Josh');
///
/// // last name signal
/// final lastName = createSignal('Brown');
///
/// // derived signal, updates automatically when firstName or lastName change
/// final fullName = createComputed(() => '${firstName()} ${lastName()}');
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
/// final counter = createSignal(0);
/// final doubleCounter = createComputed(() => counter() * 2);
/// ```
///
/// Every time the `counter` signal changes, the doubleCounter updates with the
/// new doubled `counter` value.
///
/// You can also transform the value type like:
/// ```dart
/// final counter = createSignal(0); // counter contains the value type `int`
/// final isGreaterThan5 = createComputed(() => counter() > 5); // isGreaterThan5 contains the value type `bool`
/// ```
///
/// `isGreaterThan5` will update only when the `counter` value becomes lower/greater than `5`.
/// - If the `counter` value is `0`, `isGreaterThan5` is equal to `false`.
/// - If you update the value to `1`, `isGreaterThan5` doesn't emit a new
/// value, but still contains `false`.
/// - If you update the value to `6`, `isGreaterThan5` emits a new `true` value.
/// {@endtemplate}
class Computed<T> extends ReadSignal<T> implements Derivation {
  /// {@macro computed}
  Computed(this.selector, {super.options})
      : name = options?.name ?? ReactiveContext.main.nameFor('Computed'),
        super(selector());

  @override
  // ignore: overridden_fields
  final String name;

  /// The selector applied
  final T Function() selector;

  @override
  SolidartCaughtException? _errorValue;

  @override
  // ignore: prefer_final_fields
  Set<Atom> _observables = {};

  @override
  Set<Atom>? _newObservables;

  @override
  // ignore: prefer_final_fields
  DerivationState _dependenciesState = DerivationState.notTracking;

  bool _isComputing = false;

  @override
  void dispose() {
    _context.clearObservables(this);
    super.dispose();
  }

  @override
  void _onBecomeStale() {
    _context.propagatePossiblyChanged(this);
  }

  @override
  void _suspend() {
    _context.clearObservables(this);
  }

  @override
  T get value {
    if (_isComputing) {
      // coverage:ignore-start
      throw SolidartReactionException(
        'Cycle detected in computation $name: $selector',
      );
      // coverage:ignore-end
    }

    if (!_context.isWithinBatch && _observers.isEmpty) {
      if (_context.shouldCompute(this)) {
        _context.startBatch();
        final newValue = _computeValue(track: false);
        if (newValue is T) _setValue(newValue);
        _context.endBatch();
      }
    } else {
      _reportObserved();
      if (_context.shouldCompute(this)) {
        if (_trackAndCompute()) {
          _context.propagateChangeConfirmed(this);
        }
      }
    }

    if (_context.hasCaughtException(this)) {
      throw _errorValue!;
    }
    return _value;
  }

  @override
  T? get previousValue {
    // cause observation
    value;
    return super.previousValue;
  }

  @override
  bool get hasPreviousValue {
    // cause observation
    value;
    return super._hasPreviousValue;
  }

  @override
  DisposeObservation observe(
    ObserveCallback<T> listener, {
    bool fireImmediately = false,
  }) {
    // cause observation
    final disposeEffect = createEffect((_) {
      value;
    });
    final disposeObservation = super.observe(
      listener,
      fireImmediately: fireImmediately,
    );

    return () {
      disposeEffect();
      disposeObservation();
    };
  }

  T? _computeValue({required bool track}) {
    _isComputing = true;
    _context.pushComputation();

    T? computedValue;
    if (track) {
      computedValue = _context.trackDerivation(this, selector);
    } else {
      try {
        computedValue = selector();
        _errorValue = null;
      } on Object catch (e, s) {
        _errorValue = SolidartCaughtException(e, stackTrace: s);
      }
    }

    _context.popComputation();
    _isComputing = false;

    return computedValue;
  }

  bool _trackAndCompute() {
    final oldValue = _value;
    final wasSuspended = _dependenciesState == DerivationState.notTracking;
    final hadCaughtException = _context.hasCaughtException(this);

    final newValue = _computeValue(track: true);

    final changedException =
        hadCaughtException != _context.hasCaughtException(this);
    final changed =
        wasSuspended || changedException || !_areEqual(oldValue, newValue);

    if (changed && newValue is T) {
      _setValue(newValue);
    }

    return changed;
  }

  @override
  String toString() =>
      '''Computed<$T>(value: $value, previousValue: $previousValue, options; $options)''';
}
