part of '../solidart.dart';

/// An absent optional value.
final class None<T> extends Option<T> {
  /// Creates an option with no value.
  const None();
}

/// An optional value container.
///
/// Use [Some] to represent presence and [None] to represent absence without
/// relying on `null`.
sealed class Option<T> {
  /// Base constructor for option values.
  const Option();

  /// Returns the contained value or `null` if this is [None].
  T? safeUnwrap() => switch (this) {
    Some<T>(:final value) => value,
    _ => null,
  };

  /// Returns the contained value or throws if this is [None].
  T unwrap() => switch (this) {
    Some<T>(:final value) => value,
    _ => throw StateError('Option is None'),
  };
}

/// A present optional value.
final class Some<T> extends Option<T> {
  /// Creates an option that wraps [value].
  const Some(this.value);

  /// The wrapped value.
  final T value;
}
