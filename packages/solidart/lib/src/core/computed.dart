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
class Computed<T> extends ReadSignal<T> implements Derivation {
  /// {@macro computed}
  factory Computed(
    T Function() selector, {
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

    /// {@macro SignalBase.trackPreviousValue}
    bool? trackPreviousValue,
  }) {
    return Computed._internal(
      selector: selector,
      name: name ?? ReactiveContext.main.nameFor('Computed'),
      equals: equals ?? SolidartConfig.equals,
      autoDispose: autoDispose ?? SolidartConfig.autoDispose,
      trackInDevTools: trackInDevTools ?? SolidartConfig.devToolsEnabled,
      trackPreviousValue:
          trackPreviousValue ?? SolidartConfig.trackPreviousValue,
      comparator: comparator,
    );
  }

  Computed._internal({
    required this.selector,
    required super.name,
    required super.equals,
    required super.autoDispose,
    required super.trackInDevTools,
    required super.comparator,
    required super.trackPreviousValue,
  }) : super._internal(initialValue: selector()) {
    _internalComputed = alien.Computed((previousValue) {
      if (previousValue is T) {
        super._setPreviousValue(previousValue);
      }
      try {
        return selector();
      } catch (e, s) {
        throw SolidartCaughtException(e, stackTrace: s);
      }
    });
  }

  /// The selector applied
  final T Function() selector;

  late final alien.Computed<T> _internalComputed;

  @override
  void dispose() {
    // _context.clearObservables(this);
    super.dispose();
  }

  @override
  T get value {
    if (_disposed) {
      return alien.untrack(() => _internalSignal.get());
    }
    return _internalComputed.get();
  }

  @override
  DisposeObservation observe(
    ObserveCallback<T> listener, {
    bool fireImmediately = false,
  }) {
    var skipped = false;
    return Effect((_) {
      final v = value;
      if (!fireImmediately && !skipped) {
        skipped = true;
        return;
      }
      listener(previousValue, v);
    });
  }

  @override
  String toString() =>
      '''Computed<$T>(value: $_value, previousValue: $_previousValue)''';
}
