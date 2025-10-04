import 'package:alien_signals/preset_developer.dart' as alien;
import 'package:solidart/next/core/_internal/disposable.dart';
import 'package:solidart/next/core/_internal/name_for.dart';
import 'package:solidart/next/core/_internal/readonly_signal_proxy.dart';
import 'package:solidart/next/core/config.dart';

part '_internal/solidart_signal.dart';

/// {@template solidart.ReadonlySignal}
/// A read-only [Signal].
///
/// When you don't need to expose the setter of a [Signal],
/// you should consider transforming it in a [ReadonlySignal]
/// using the `toReadonly` method.
///
/// All derived-signals are [ReadonlySignal]s because they depend
/// on the value of a [Signal].
/// {@endtemplate}
abstract interface class ReadonlySignal<T> {
  /// {@template solidart.ReadonlySignal.name}
  /// The name of the signal, useful for logging purposes.
  /// {@endtemplate}
  String get name;

  /// {@template solidart.ReadonlySignal.equals}
  /// Whether to check the equality of the value with the == equality.
  ///
  /// Preventing signal updates if the new value is equal to the previous.
  ///
  /// When this value is true, the [comparator] is not used.
  /// {@endtemplate}
  bool get equals;

  /// {@template solidart.ReadonlySignal.comparator}
  /// An optional comparator function, defaults to [identical].
  ///
  /// Preventing signal updates if the [comparator] returns true.
  ///
  /// Taken into account only if [equals] is false.
  /// {@endtemplate}
  bool Function(T?, T?) get comparator;

  /// {@template solidart.ReadonlySignal.autoDispose}
  /// Whether to automatically dispose the signal (defaults to
  /// [SolidartConfig.autoDispose]).
  ///
  /// This happens automatically when there are no longer subscribers.
  /// If you set it to false, you should remember to dispose the signal manually
  /// {@endtemplate}
  bool get autoDispose;

  /// Whether to track the signal in the DevTools extension, defaults to
  /// [SolidartConfig.devToolsEnabled].
  bool get trackInDevTools;

  /// Whether to track the previous value of the signal, defaults to true
  bool get trackPreviousValue;

  /// The current signal value
  T get value;

  /// Whether or not the signal has been initialized with a value.
  bool get hasValue;

  /// The previous signal value
  ///
  /// Defaults to null when no previous value is present.
  T? get previousValue;

  // Indicates if there is a previous value. It is especially
  /// helpful if [T] is nullable.
  bool get hasPreviousValue;

  /// Returns the untracked value of the signal.
  T get untrackedValue;

  /// Returns the untracked previous value of the signal.
  T? get untrackedPreviousValue;

  /// The total number of listeners subscribed to the signal.
  int get listenerCount;

  /// Fired when the signal is disposing
  void onDispose(void Function() callback);

  /// Diposes the signal
  void dispose();
}

/// {@template solidart.Signal}
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
///
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
abstract interface class Signal<T> implements ReadonlySignal<T> {
  /// {@macro solidart.Signal}
  factory Signal(T initialValue,
      {bool autoDispose,
      bool Function(T?, T?) comparator,
      bool equals,
      bool trackInDevTools,
      bool trackPreviousValue}) = SolidartSignal;

  /// This is a lazy signal, it doesn't have a value at the moment of creation.
  /// But would throw a StateError if you try to access the value before setting
  /// one.
  ///
  /// {@macro solidart.Signal}
  factory Signal.lazy(
      {bool autoDispose,
      bool Function(T?, T?) comparator,
      bool equals,
      bool trackInDevTools,
      bool trackPreviousValue}) = SolidartSignal.lazy;

  /// Sets the current signal value with [newValue].
  ///
  /// This operation may be skipped if the value is equal to the previous one,
  /// check [equals] and [comparator].
  /// ignore: avoid_setters_without_getters
  set value(T newValue);

  /// Returns a readonly version of this signal.
  ReadonlySignal<T> toReadonly();
}
