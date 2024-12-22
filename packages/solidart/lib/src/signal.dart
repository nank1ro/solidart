import 'package:alien_signals/alien_signals.dart';
import 'package:solidart/src/devtools/_utils.dart';
import 'package:solidart/src/namespace.dart';

/// Solidart signal options
abstract class SignalOptions {
  /// Creates a new signal options.
  SignalOptions({
    required this.name,
    this.comparator = identical,
    bool? equals,
  }) : equals = equals ?? Solidart.equals;

  /// {@template solidart.signal.name}
  /// The name of the signal, useful for logging purposes.
  /// {@endtemplate}
  final String name;

  /// {@template solidart.signal.comparator}
  /// An optional comparator function, defaults to [identical].
  ///
  /// Preventing signal updates if the [comparator] returns true.
  ///
  /// Taken into account only if [equals] is false.
  /// {@endtemplate}
  final bool Function(Object? a, Object? b) comparator;

  /// {@template solidart.signal.equals}
  /// Whether to check the equality of the value with the == equality.
  ///
  /// Preventing signal updates if the new value is equal to the previous.
  ///
  /// When this value is true, the [comparator] is not used.
  /// {@endtemplate}
  final bool equals;
}

// ignore: public_member_api_docs
abstract interface class ReadableSignal<T> implements SignalOptions {
  // ignore: public_member_api_docs
  T get value;
}

// ignore: public_member_api_docs
abstract interface class Signal<T> implements ReadableSignal<T> {
  factory Signal(
    T value, {
    String name,
    bool Function(Object? a, Object? b) comparator,
    bool equals,
  }) = _Signal;

  // ignore: inference_failure_on_untyped_parameter, avoid_setters_without_getters
  set value(_);
}

final class _Signal<T> extends SignalOptions
    implements Signal<T>, Dependency<T> {
  _Signal(
    this.currentValue, {
    super.name = 'Signal',
    super.comparator,
    super.equals,
  }) {
    notifyDevToolsAboutSignal(this, eventType: DevToolsEventType.created);
    if (Solidart.dev && Solidart.observers.isNotEmpty) {
      for (final obs in Solidart.observers) {
        obs.didCreateSignal(this);
      }
    }
  }

  @override
  T currentValue;

  @override
  int? lastTrackedId = 0;

  @override
  Link? subs;

  @override
  Link? subsTail;

  @override
  T get value {
    if (activeTrackId != 0 && lastTrackedId != activeTrackId) {
      lastTrackedId = activeTrackId;
      link(this, activeSub!);
    }

    return currentValue;
  }

  @override
  set value(T value) {
    final comparator = equals ? this.comparator : _eq;
    if (!comparator(currentValue, value)) {
      currentValue = value;
      if (subs != null) propagate(subs);

      notifyDevToolsAboutSignal(this, eventType: DevToolsEventType.updated);
      if (Solidart.dev && Solidart.observers.isNotEmpty) {
        for (final obs in Solidart.observers) {
          obs.didUpdateSignal(this);
        }
      }
    }
  }
}

bool _eq(Object? a, Object? b) => a == b;
