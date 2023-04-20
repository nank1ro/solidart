import 'package:meta/meta.dart';

/// Signature of callbacks that have no arguments and return no data.
typedef VoidCallback = void Function();

/// Dispose function
typedef Dispose = void Function();

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

/// The callback fired by the observer
typedef ObserveCallback<T> = void Function(T? previousValue, T? value);
