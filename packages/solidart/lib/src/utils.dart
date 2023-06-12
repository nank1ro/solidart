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

/// coverage:ignore-end

/// {@template data}
/// A wrapper class that makes it possible to distinguish
/// between `null` as valid instance of [T] and `null` as not present.
/// Especially useful if [T] is nullable.
/// {@endtemplate}
@immutable
class Wrapped<T> {
  /// {@macro data}
  const Wrapped(T value) : _value = value;

  final T _value;

  /// Unwraps the data held by the instance. Usage examples:
  ///
  /// - If [T] is nullable:
  ///
  /// ```dart
  ///   try {
  ///     final wrappedData = userResourceState.wrappedData;
  ///     if (wrappedData == null) {
  ///       // in loading state
  ///
  ///       // do something signalizing we are in loading state
  ///     } else {
  ///       // in data state
  ///
  ///       final data = wrappedData.unwrap();
  ///       if (data == null) {
  ///         // do something with data-is-null case
  ///       } else {
  ///         // do something with data
  ///       }
  ///     }
  ///   } catch (e) {
  ///     // in error state
  /// 
  ///     // handle error
  ///   }
  /// ```
  ///
  /// - If [T] is not nullable:
  ///
  ///   ```dart
  ///   try {
  ///     final wrappedData = userResourceState.wrappedData;
  ///     if (wrappedData == null) {
  ///       // in loading state
  /// 
  ///       // do something signalizing we are in loading state
  ///     } else {
  ///       // in data state
  ///
  ///       final data = wrappedData.unwrap(); // no need to make distinction
  ///       // do something with data
  ///     }
  ///   } catch (e) {
  ///     // in error state
  /// 
  ///     // handle error
  ///   }
  ///   ```
  T get unwrap => _value;

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is Wrapped &&
    runtimeType == other.runtimeType &&
    _value == other._value;

  @override
  int get hashCode => _value.hashCode;
}
