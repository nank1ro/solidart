import 'dart:async';

import 'package:meta/meta.dart';

/// coverage:ignore-start
/// Signature of callbacks that have no arguments and return no data.
typedef VoidCallback = void Function();

/// Error callback
typedef ErrorCallback = void Function(Object error);

/// The callback fired by the observer
typedef ObserveCallback<T> = void Function(T? previousValue, T value);

/// {@template solidartexception}
/// An Exception class to capture Solidart specific exceptions
/// {@endtemplate}
@immutable
class SolidartException extends Error implements Exception {
  /// {@macro solidartexception}
  SolidartException(this.message);

  /// The error message
  final String message;

  @override
  String toString() => message;
}

/// {@template solidartreactionexception}
/// This exception would be fired when an reaction has a cycle and does
/// not stabilize in `ReactiveConfig.maxIterations` iterations
/// {@endtemplate}
class SolidartReactionException extends SolidartException {
  /// {@macro solidartreactionexception}
  SolidartReactionException(super.message);
}

/// {@template solidartcaughtexception}
/// This captures the stack trace when user-land code throws an exception
/// {@endtemplate}
class SolidartCaughtException extends SolidartException {
  /// {@macro solidartcaughtexception}
  SolidartCaughtException(Object exception, {required StackTrace stackTrace})
      : _exception = exception,
        _stackTrace = stackTrace,
        super('SolidartException: $exception');

  final Object _exception;
  final StackTrace _stackTrace;

  /// the exception
  Object get exception => _exception;

  /// The stacktrace
  @override
  StackTrace? get stackTrace => _stackTrace;
}

/// Creates a delayer scheduler with the given [duration].
Timer Function(void Function()) createDelayedScheduler(Duration duration) =>
    (fn) => Timer(duration, fn);

/// The `Option` class represents an optional value.

/// It is either `Some` or `None`.
/// Use `unwrap` to get the value of a `Some` or throw an exception if it is a
/// `None`.
/// Or safely switch the sealed class to get the value.
sealed class Option<T> {
  const Option();

  /// Unwraps the option, yielding the content of a `Some`.
  T unwrap() {
    return switch (this) {
      final Some<T> some => some.value,
      _ => throw Exception('Cannot unwrap None'),
    };
  }

  /// Safe unwraps the option, yielding the content of a `Some` or `null`.
  T? safeUnwrap() {
    return switch (this) {
      final Some<T> some => some.value,
      _ => null,
    };
  }
}

/// {@template some}
/// The `Some` class represents a value of type `T`.
/// {@endtemplate}
class Some<T> extends Option<T> {
  /// {@macro some}
  const Some(this.value);

  /// Te value of the `Some` class.
  final T value;
}

/// {@template none}
/// The `None` class represents an absence of a value.
/// {@endtemplate}
class None<T> extends Option<T> {
  /// {@macro none}
  const None();
}

/// coverage:ignore-end
