import 'package:meta/meta.dart';
import 'package:solidart/src/core/readable_signal.dart';
import 'package:solidart/src/core/signal_options.dart';

/// Creates a simple reactive state with a getter and setter.
///
/// When you change a signal's value, it automatically updates any listener.
Signal<T> createSignal<T>(
  T value, {
  SignalOptions<T>? options,
}) {
  final effectiveOptions = options ?? SignalOptions<T>();
  return Signal<T>(value, options: effectiveOptions);
}

class Signal<T> extends ReadableSignal<T> {
  Signal(
    super.initialValue, {
    required super.options,
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
