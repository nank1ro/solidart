part of 'core.dart';

// coverage:ignore-start

/// {@macro computed}
@Deprecated('Use Computed instead')
Computed<T> createComputed<T>(
  T Function() selector, {
  SignalOptions<T>? options,
}) =>
    Computed<T>(selector, options: options);

// coverage:ignore-end

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
class Computed<T> extends ReadSignal<T> with alien.Subscriber {
  /// {@macro computed}
  factory Computed(
    T Function() selector, {
    SignalOptions<T>? options,
  }) {
    final name = options?.name ?? 'Computed<$T>';
    final effectiveOptions =
        (options ?? SignalOptions<T>(name: name)).copyWith(name: name);
    return Computed._internal(
      selector: selector,
      name: name,
      options: effectiveOptions,
    );
  }

  Computed._internal({
    required this.selector,
    required super.name,
    required super.options,
  }) : super._internal(initialValue: selector());

  /// The selector applied
  final T Function() selector;

  @override
  void dispose() {
    system.disposeSub(this);
    super.dispose();
  }

  @override
  T get value {
    if ((flags &
            (alien.SubscriberFlags.dirty |
                alien.SubscriberFlags.pendingComputed)) !=
        0) {
      system.processComputedUpdate(this, flags);
    }
    if (system.activeSub != null) {
      system.link(this, system.activeSub!);
    } else if (system.activeScope != null) {
      system.link(this, system.activeScope!);
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
    final disposeEffect = Effect((_) {
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

  bool _compute() {
    final oldValue = _value;
    final newValue = selector();
    final changed = !_areEqual(oldValue, newValue);

    if (changed) {
      _value = newValue;
    }

    return changed;
  }

  @override
  String toString() =>
      '''Computed<$T>(value: $_value, previousValue: $_previousValue, options; $options)''';

  @override
  int flags = alien.SubscriberFlags.computed | alien.SubscriberFlags.dirty;
}
