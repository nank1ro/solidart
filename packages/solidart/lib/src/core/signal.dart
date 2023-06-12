import 'package:meta/meta.dart';
import 'package:solidart/src/core/reactive_context.dart';
import 'package:solidart/src/core/read_signal.dart';
import 'package:solidart/src/core/signal_base.dart';
import 'package:solidart/src/core/signal_options.dart';
import 'package:solidart/src/utils.dart';

/// {@macro signal}
Signal<T> createSignal<T>(
  T value, {
  SignalOptions<T>? options,
}) {
  final name = options?.name ?? ReactiveContext.main.nameFor('Signal');
  final effectiveOptions = options ?? SignalOptions<T>(name: name);
  return Signal<T>(value, options: effectiveOptions);
}

/// {@template signal}
/// # Signals
/// Signals are the cornerstone of reactivity in `solidart`. They contain
/// values that change over time; when you change a signal's value, it
/// automatically updates anything that uses it.
///
/// Create the signal with:
///
/// ```dart
/// final counter = createSignal(0);
/// ````
///
/// The argument passed to the create call is the initial value, and the return
/// value is the signal.
///
/// To retrieve the current signal value use:
/// ```dart
/// counter.value; // 0
/// // or
/// counter(); // 0
/// ```
///
/// To update the current signal value you can use:
/// ```dart
/// counter.value++; // increase by 1
/// // or
/// counter.set(2); // sets the value to 2
/// // or
/// counter.value = 5; // sets the value to 5
/// // or
/// counter.update((v) => v * 2); // update based on the current value
/// ```
///
/// > Don't forget to call the dispose method when you no longer need the signal
/// ```dart
/// counter.dispose();
/// ```

/// ## Derived Signals
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
/// final age = createComputed(() => user().age);
///
/// // adding an effect to print the age
/// createEffect((_) {
///   print('age changed from ${age.previousValue} into ${age.value}');
/// });
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
/// You can also transform the value type into a `bool`:
/// ```dart
/// final counter = createSignal(0); // type: int
/// final isGreaterThan5 = createComputed(() => counter() > 5); // type: bool
/// ```
///
/// `isGreaterThan5` will update only when the `counter` value becomes lower/greater than `5`.
/// - If the `counter` value is `0`, `isGreaterThan5` is equal to `false`.
/// - If you update the value to `1`, `isGreaterThan5` doesn't emit a new
/// value, but still contains `false`.
/// - If you update the value to `6`, `isGreaterThan5` emits a new `true` value.
/// {@endtemplate}
class Signal<T> extends ReadSignal<T> {
  /// {@macro signal}
  Signal(
    super.initialValue, {
    super.options,
  }) : _value = initialValue;

  // Tracks the internal value
  T _value;
  // Tracks the internal previous value
  Wrapped<T>? _previousValue;

  @override
  T get value {
    reportObserved();
    return _value;
  }

  /// {@macro set-signal-value}
  set value(T newValue) => set(newValue);

  /// {@template set-signal-value}
  /// Sets the current signal value with [newValue].
  ///
  /// This operation may be skipped if the value is equal to the previous one,
  /// check [SignalOptions.equals] and [SignalOptions.comparator].
  /// {@endtemplate}
  void set(T newValue) {
    // skip if the value are equals
    if (areEqual(_value, newValue)) {
      return;
    }

    // store the previous value
    _previousValue = Wrapped(_value);

    // notify with the new value
    _value = newValue;
    reportChanged();
    _notifyListeners();
  }

  /// Indicates if the [oldValue] and the [newValue] are equal.
  @internal
  bool areEqual(T oldValue, T newValue) {
    // skip if the value are equals
    if (options.equals && oldValue == newValue) {
      return true;
    }

    // skip if the [comparator] returns true
    if (!options.equals && options.comparator != null) {
      return options.comparator!(oldValue, newValue);
    }

    return false;
  }

  /// The previous value, if any.
  @override
  Wrapped<T>? get previousValue {
    reportObserved();
    return _previousValue;
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

  /// Calls a function with the current [value] and assigns the result as the
  /// new value.
  T update(T Function(T value) callback) => value = callback(value);

  /// Converts this [Signal] into a [ReadSignal]
  /// Use this method to remove the visility to the value setter.
  ReadSignal<T> toReadSignal() => this;

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
  String toString() =>
      '''Signal<$T>(value: $value, previousValue: $previousValue, options: $options)''';
}
