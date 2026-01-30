part of '../solidart.dart';

/// {@template solidart.observer}
/// Observer for signal lifecycle events.
///
/// Use this for logging or instrumentation without depending on DevTools:
/// ```dart
/// class Logger extends SolidartObserver {
///   @override
///   void didCreateSignal(ReadonlySignal<Object?> signal) {
///     print('created: ${signal.identifier.value}');
///   }
///   @override
///   void didUpdateSignal(ReadonlySignal<Object?> signal) {}
///   @override
///   void didDisposeSignal(ReadonlySignal<Object?> signal) {}
/// }
///
/// SolidartConfig.observers.add(Logger());
/// ```
/// {@endtemplate}
abstract class SolidartObserver {
  /// {@macro solidart.observer}
  const SolidartObserver(); // coverage:ignore-line

  /// Called when a signal is created.
  void didCreateSignal(ReadonlySignal<Object?> signal);

  /// Called when a signal is disposed.
  void didDisposeSignal(ReadonlySignal<Object?> signal);

  /// Called when a signal updates.
  void didUpdateSignal(ReadonlySignal<Object?> signal);
}
