part of 'core.dart';

/// {@template signal}
/// # Signals
/// Signals are the cornerstone of reactivity in `solidart`. They contain
/// values that change over time; when you change a signal's value, it
/// automatically updates anything that uses it.
///
/// Create the signal with:
///
/// ```dart
/// final counter = Signal(0);
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
/// final user = Signal(const User(name: "name", age: 20));
///
/// // create a derived signal just for the age
/// final age = Computed(() => user().age);
///
/// // adding an effect to print the age
/// Effect((_) {
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
/// final counter = Signal(0);
/// final doubleCounter = Computed(() => counter() * 2);
/// ```
///
/// Every time the `counter` signal changes, the doubleCounter updates with the
/// new doubled `counter` value.
///
/// You can also transform the value type into a `bool`:
/// ```dart
/// final counter = Signal(0); // type: int
/// final isGreaterThan5 = Computed(() => counter() > 5); // type: bool
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
  factory Signal(
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
  }) {
    return Signal._internal(
      initialValue: initialValue,
      name: name ?? ReactiveContext.main.nameFor('Signal'),
      equals: equals ?? SolidartConfig.equals,
      autoDispose: autoDispose ?? SolidartConfig.autoDispose,
      trackInDevTools: trackInDevTools ?? SolidartConfig.devToolsEnabled,
      comparator: comparator,
    );
  }

  Signal._internal({
    required super.initialValue,
    required super.name,
    required super.equals,
    required super.autoDispose,
    required super.trackInDevTools,
    required super.comparator,
  }) : super._internal();

  /// {@macro set-signal-value}
  set value(T newValue) => set(newValue);

  /// {@template set-signal-value}
  /// Sets the current signal value with [newValue].
  ///
  /// This operation may be skipped if the value is equal to the previous one,
  /// check [equals] and [comparator].
  /// {@endtemplate}
  void set(T newValue) => _setValue(newValue);

  /// Calls a function with the current value and assigns the result as the
  /// new value.
  T updateValue(T Function(T value) callback) => value = callback(_value);

  /// Converts this [Signal] into a [ReadSignal]
  /// Use this method to remove the visility to the value setter.
  ReadSignal<T> toReadSignal() => this;

  @override
  String toString() =>
      '''Signal<$T>(value: $_value, previousValue: $_previousValue)''';
}
