import 'package:solidart/solidart.dart';
import 'package:solidart/src/core/atom.dart';
import 'package:solidart/src/core/derivation.dart';
import 'package:solidart/src/utils.dart';

/// {@macro computed}
ReadSignal<T> createComputed<T>(
  T Function() selector,
) =>
    Computed<T>(selector: selector).toReadSignal();

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
    SignalOptions<T>? options,
  }) : super(selector(), options: options);

  /// The selector applied
  final T Function() selector;

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
        final newValue = _computeValue(track: false);
        if (newValue != null) {
          value = newValue;
        }
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
      throw errorValue!;
    }

    return unobservedValue;
  }

  T? _computeValue({required bool track}) {
    _isComputing = true;
    context.pushComputation();

    T? value;
    if (track) {
      value = context.trackDerivation(this, selector);
    } else {
      if (context.config.disableErrorBoundaries) {
        value = selector();
      } else {
        try {
          value = selector();
          errorValue = null;
        } on Object catch (e, s) {
          errorValue = SolidartCaughtException(e, stackTrace: s);
        }
      }
    }

    context.popComputation();
    _isComputing = false;

    return value;
  }

  bool _trackAndCompute() {
    final oldValue = unobservedValue;
    final wasSuspended = dependenciesState == DerivationState.notTracking;
    final hadCaughtException = context.hasCaughtException(this);

    final newValue = _computeValue(track: true);

    final changedException =
        hadCaughtException != context.hasCaughtException(this);
    final changed =
        wasSuspended || changedException || !areEqual(oldValue, newValue);

    if (changed && newValue != null) {
      value = newValue;
    }

    return changed;
  }
}
