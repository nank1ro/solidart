import 'package:solidart/src2/core/signal.dart';

/// {@template solidart-observer}
/// An object that listens to the changes of the reactive system.
///
/// This can be used for logging purposes.
/// {@endtemplate}
abstract class SolidartObserver {
  // coverage:ignore-start

  /// {@macro solidart-observer}
  const SolidartObserver();
  // coverage:ignore-end

  /// A signal has been created.
  void didCreateSignal(ReadonlySignal<Object?> signal);

  /// A signal has been updated.
  void didUpdateSignal(ReadonlySignal<Object?> signal);

  /// A signal has been disposed.
  void didDisposeSignal(ReadonlySignal<Object?> signal);
}
