import 'package:solidart/src/core/signal.dart';
import 'package:solidart/src/core/signal_options.dart';

/// {@template signalselector}
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
class SignalSelector<Input, Output> extends Signal<Output> {
  /// {@macro signalselector}
  SignalSelector({
    required this.signal,
    required this.selector,
    SignalOptions<Output>? options,
  }) : super(
          selector(signal.value),
          options: options ?? SignalOptions<Output>(),
        ) {
    // dispose the [SignalSelector] when the signal disposes
    signal.onDispose(dispose);
    _listenAndSelect();
  }

  /// The signal on which to select
  final Signal<Input> signal;

  /// The selector applied
  final Output Function(Input) selector;

  void _listener() {
    previousValue =
        // ignore: null_check_on_nullable_type_parameter
        signal.previousValue == null ? null : selector(signal.previousValue!);
    value = selector(signal.value);
  }

  void _listenAndSelect() {
    signal.addListener(_listener);
  }

  @override
  void dispose() {
    signal.removeListener(_listener);
    super.dispose();
  }
}
