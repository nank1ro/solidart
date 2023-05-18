import 'package:solidart/src/core/atom.dart';
import 'package:solidart/src/core/derivation.dart';
import 'package:solidart/src/core/effect.dart';
import 'package:solidart/src/core/reactive_context.dart';
import 'package:solidart/src/core/read_signal.dart';
import 'package:solidart/src/core/signal.dart';
import 'package:solidart/src/core/signal_options.dart';
import 'package:solidart/src/utils.dart';

/// {@macro computed}
ReadSignal<T> createComputed<T>(
  T Function() selector, {
  SignalOptions<T>? options,
  ErrorCallback? onError,
}) =>
    Computed<T>(selector: selector, options: options, onError: onError)
        .toReadSignal();

/// {@template computed}
/// A special [Signal] that notifies only whenever the selected
/// value changes.
///
/// You may want to subscribe only to a sub-field of a `Signal` value.
/// ```dart
/// // sample User class
/// class User {
///   const User({
///     required this.name,
///     required this.age,
///   });
///
///   final String name;
///   final int age;
///
///   User copyWith({
///     String? name,
///     int? age,
///   }) {
///     return User(
///       name: name ?? this.name,
///       age: age ?? this.age,
///     );
///   }
/// }
///
/// // create a user signal
/// final user = createSignal(const User(name: "name", age: 20));
///
/// // create a derived signal just for the age
/// final age = user.select((value) => value.age);
///
/// // adding an effect to print the age
/// createEffect(() {
///   print('age changed from ${age.previousValue} into ${age.value}');
/// }, signals: [age]);
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
/// final doubleCounter = counter.select((value) => value * 2);
/// ```
///
/// Every time the `counter` signal changes, the doubleCounter updates with the
/// new doubled `counter` value.
///
/// You can also transform the value type like:
/// ```dart
/// ReadSignal<bool>
/// final counter = createSignal(0); // int
/// final isGreaterThan5 = counter.select((value) => value > 5); // bool
/// ```
///
/// `isGreaterThan5` will update only when the `counter` value becomes lower/greater than `5`.
/// - If the `counter` value is `0`, `isGreaterThan5` is equal to `false`.
/// - If you update the value to `1`, `isGreaterThan5` doesn't emit a new
/// value, but still contains `false`.
/// - If you update the value to `6`, `isGreaterThan5` emits a new `true` value.
/// {@endtemplate}
class Computed<T> extends Signal<T> implements Derivation {
  /// {@macro computed}
  Computed({
    required this.selector,
    ErrorCallback? onError,
    SignalOptions<T>? options,
  })  : _onError = onError,
        name = options?.name ?? ReactiveContext.main.nameFor('Computed'),
        super(selector(), options: options);

  // Tracks the internal value
  T? _value;

  // Tracks the internal previous value
  T? _previousValue;

  @override
  // ignore: overridden_fields
  final String name;

  /// The selector applied
  final T Function() selector;

  /// Optionally handle the error case
  final ErrorCallback? _onError;

  @override
  SolidartCaughtException? errorValue;

  @override
  Set<Atom> observables = {};

  @override
  Set<Atom>? newObservables;

  @override
  DerivationState dependenciesState = DerivationState.notTracking;

  bool _isComputing = false;

  @override
  void dispose() {
    context.clearObservables(this);
    super.dispose();
  }

  @override
  void onBecomeStale() {
    context.propagatePossiblyChanged(this);
  }

  @override
  void suspend() {
    context.clearObservables(this);
  }

  @override
  T get value {
    if (_isComputing) {
      throw SolidartReactionException(
        'Cycle detected in computation $name: $selector',
      );
    }

    if (!context.isWithinBatch && observers.isEmpty) {
      if (context.shouldCompute(this)) {
        context.startBatch();
        _value = _computeValue(track: false);
        context.endBatch();
      }
    } else {
      reportObserved();
      if (context.shouldCompute(this)) {
        if (_trackAndCompute()) {
          context.propagateChangeConfirmed(this);
        }
      }
    }

    if (context.hasCaughtException(this)) {
      if (_onError != null) {
        _onError!.call(errorValue!);
      } else {
        throw errorValue!;
      }
    }
    return _value as T;
  }

  /// The previous value, if any.
  @override
  T? get previousValue {
    final prevVal = _value;

    if (_isComputing) {
      throw SolidartReactionException(
        'Cycle detected in computation $name: $selector',
      );
    }

    if (!context.isWithinBatch && observers.isEmpty) {
      if (context.shouldCompute(this)) {
        context.startBatch();
        _value = _computeValue(track: false);
        context.endBatch();
      }
    } else {
      reportObserved();
      if (context.shouldCompute(this)) {
        if (_trackAndCompute()) {
          context.propagateChangeConfirmed(this);
        }
      }
    }

    if (context.hasCaughtException(this)) {
      if (_onError != null) {
        _onError!.call(errorValue!);
      } else {
        throw errorValue!;
      }
    }
    return _previousValue = prevVal;
  }

  @override
  DisposeEffect observe(
    ObserveCallback<T> listener, {
    bool fireImmediately = false,
  }) {
    var ignore = !fireImmediately;

    void notifyChange() {
      if (ignore) {
        ignore = false;
        return;
      }
      context.untracked(() {
        listener(_previousValue, value);
      });
    }

    return createEffect((_) {
      final newValue = value;

      notifyChange();

      _previousValue = newValue;
    });
  }

  T? _computeValue({required bool track}) {
    _isComputing = true;
    context.pushComputation();

    T? computedValue;
    if (track) {
      computedValue = context.trackDerivation(this, selector);
    } else {
      try {
        computedValue = selector();
        errorValue = null;
      } on Object catch (e, s) {
        errorValue = SolidartCaughtException(e, stackTrace: s);
        if (_onError != null) {
          _onError!.call(errorValue!);
        } else {
          context.popComputation();
          _isComputing = false;
          throw errorValue!;
        }
      }
    }

    context.popComputation();
    _isComputing = false;

    return computedValue;
  }

  bool _trackAndCompute() {
    final oldValue = _value;
    final wasSuspended = dependenciesState == DerivationState.notTracking;
    final hadCaughtException = context.hasCaughtException(this);

    final newValue = _computeValue(track: true);

    final changedException =
        hadCaughtException != context.hasCaughtException(this);
    final changed =
        wasSuspended || changedException || !areEqual(oldValue, newValue);

    if (changed) {
      _previousValue = oldValue;
      _value = newValue;
    }

    return changed;
  }
}
