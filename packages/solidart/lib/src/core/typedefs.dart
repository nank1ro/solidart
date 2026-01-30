part of '../solidart.dart';

/// Disposer returned by [ObserveSignal.observe].
typedef DisposeObservation = void Function();

/// Signature for callbacks fired when a signal changes.
typedef ObserveCallback<T> = void Function(T? previousValue, T value);

/// Compares two values for equality.
///
/// Return `true` when the update should be skipped because values are
/// considered equivalent.
typedef ValueComparator<T> = bool Function(T? a, T? b);

/// Lazily produces a value.
typedef ValueGetter<T> = T Function();

/// A callback that returns no value.
typedef VoidCallback = ValueGetter<void>;
