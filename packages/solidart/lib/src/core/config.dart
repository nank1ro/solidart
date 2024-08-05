part of 'core.dart';

/// {@template solidart-config}
/// The global configuration of the reactive system.
/// {@endtemplate}
abstract class SolidartConfig {
  /// {@macro SignalBase.equals}
  static bool equals = false;

  /// Whether to enable the auto disposal of the reactive system, defaults to
  /// true.
  static bool autoDispose = true;

  /// Whether to enable the DevTools extension, defaults to false.
  static bool devToolsEnabled = false;

  /// The list of observers.
  static final observers = <SolidartObserver>[];
}

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
  void didCreateSignal(SignalBase<Object?> signal);

  /// A signal has been updated.
  void didUpdateSignal(SignalBase<Object?> signal);

  /// A signal has been disposed.
  void didDisposeSignal(SignalBase<Object?> signal);
}
