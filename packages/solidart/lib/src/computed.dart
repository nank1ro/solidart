import 'package:alien_signals/preset_developer.dart' as alien;
import 'package:solidart/src/_internal/devtools.dart';
import 'package:solidart/src/_internal/disposable.dart';
import 'package:solidart/src/_internal/name_for.dart';
import 'package:solidart/src/config.dart';
import 'package:solidart/src/signal.dart';

part '_internal/solidart_computed.dart';

/// {@template solidart.Computed}
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
abstract interface class Computed<T> implements ReadonlySignal<T> {
  /// {@macro solidart.Computed}
  factory Computed(T Function() selector,
      {bool? autoDispose,
      bool Function(T?, T?)? comparator,
      String? name,
      bool? equals,
      bool? trackInDevTools,
      bool? trackPreviousValue}) = SolidartComputed<T>;
}
