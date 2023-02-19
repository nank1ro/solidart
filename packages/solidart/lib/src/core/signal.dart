import 'package:meta/meta.dart';
import 'package:solidart/src/core/readable_signal.dart';
import 'package:solidart/src/core/signal_options.dart';

/// # Signals
/// Signals are the cornerstone of reactivity in `solidart`. They contain values that change over time; when you change a signal's value, it automatically updates anything that uses it.
///
/// Create the signal with:
///
/// ```dart
/// final counter = createSignal(0);
/// ````
///
/// The argument passed to the create call is the initial value, and the return value is the signal.
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
/// counter.value = 5; // sets the value to 5
/// // or
/// counter.update((v) => v * 2); // update based on the current value
/// ```
///
/// > Don't forget to call the `dispose()` method when you no longer need the signal.
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
/// A derived signal is not of type `Signal` but is a `ReadableSignal`.
/// The difference with a normal `Signal` is that a `ReadableSignal` doesn't have a value setter, in other words it's a __read-only__ signal.
///
/// You can also use derived signals in other ways, like here:
/// ```dart
/// final counter = createSignal(0);
/// final doubleCounter = counter.select((value) => value * 2);
/// ```
///
/// Every time the `counter` signal changes, the doubleCounter updates with the new doubled `counter` value.
///
/// You can also transform the value type like:
/// ```dart
/// ReadableSignal<bool>
/// final counter = createSignal(0); // int
/// final isGreaterThan5 = counter.select((value) => value > 5); // bool
/// ```
///
/// `isGreaterThan5` will update only when the `counter` value becomes lower/greater than `5`.
/// - If the `counter` value is `0`, `isGreaterThan5` is equal to `false`.
/// - If you update the value to `1`, `isGreaterThan5` doesn't emit a new value, but still contains `false`.
/// - If you update the value to `6`, `isGreaterThan5` emits a new `true` value.
Signal<T> createSignal<T>(
  T value, {
  SignalOptions<T>? options,
}) {
  final effectiveOptions = options ?? SignalOptions<T>();
  return Signal<T>(value, options: effectiveOptions);
}

/// # Signals
/// Signals are the cornerstone of reactivity in `solidart`. They contain values that change over time; when you change a signal's value, it automatically updates anything that uses it.
///
/// Create the signal with:
///
/// ```dart
/// final counter = createSignal(0);
/// ````
///
/// The argument passed to the create call is the initial value, and the return value is the signal.
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
/// counter.value = 5; // sets the value to 5
/// // or
/// counter.update((v) => v * 2); // update based on the current value
/// ```
///
/// > Don't forget to call the `dispose()` method when you no longer need the signal.
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
/// A derived signal is not of type `Signal` but is a `ReadableSignal`.
/// The difference with a normal `Signal` is that a `ReadableSignal` doesn't have a value setter, in other words it's a __read-only__ signal.
///
/// You can also use derived signals in other ways, like here:
/// ```dart
/// final counter = createSignal(0);
/// final doubleCounter = counter.select((value) => value * 2);
/// ```
///
/// Every time the `counter` signal changes, the doubleCounter updates with the new doubled `counter` value.
///
/// You can also transform the value type like:
/// ```dart
/// ReadableSignal<bool>
/// final counter = createSignal(0); // int
/// final isGreaterThan5 = counter.select((value) => value > 5); // bool
/// ```
///
/// `isGreaterThan5` will update only when the `counter` value becomes lower/greater than `5`.
/// - If the `counter` value is `0`, `isGreaterThan5` is equal to `false`.
/// - If you update the value to `1`, `isGreaterThan5` doesn't emit a new value, but still contains `false`.
/// - If you update the value to `6`, `isGreaterThan5` emits a new `true` value.
class Signal<T> extends ReadableSignal<T> {
  Signal(
    super.initialValue, {
    super.options,
  }) : _value = initialValue;

  T _value;

  @override
  T get value => _value;

  /// Updates the current signal value with [newValue].
  ///
  /// This operation may be skipped if the value is equal to the previous one,
  /// check [SignalOptions.equals] and [SignalOptions.comparator].
  set value(T newValue) {
    // skip if the value are equals
    // TODO(alex): add specific equality based on type, e.g. DeepCollectionEquality
    if (options.equals && value == newValue) {
      return;
    }

    // skip if the [comparator] returns true
    if (!options.equals && options.comparator != null) {
      final areEqual = options.comparator!(value, newValue);
      if (areEqual) return;
    }

    // store the previous value
    _previousValue = value;
    // notify with the new value
    _value = newValue;
    notifyListeners();
  }

  T? _previousValue;

  /// The previous value, if any.
  @override
  T? get previousValue => _previousValue;

  /// Sets the previous value.
  ///
  /// Never use this method.
  @internal
  @protected
  set previousValue(T? newPreviousValue) {
    _previousValue = newPreviousValue;
  }

  /// Calls a function with the current [value] and assigns the result as the
  /// new value.
  T update(T Function(T value) callback) => value = callback(value);

  /// Converts this [Signal] into a [ReadableSignal]
  /// Use this method to remove the visility to the value setter.
  ReadableSignal<T> get readable => this;

  @override
  String toString() =>
      '''Signal<$T>(value: $value, previousValue: $previousValue, options; $options)''';
}
