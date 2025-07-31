part of 'core.dart';

/// {@template solidart-config}
/// The global configuration of the reactive system.
/// {@endtemplate}
abstract class SolidartConfig {
  /// Whether to use the equality operator when updating the signal, defaults to
  /// false
  static bool equals = false;

  /// Whether to enable the auto disposal of the reactive system, defaults to
  /// true.
  static bool autoDispose = true;

  /// Whether to enable the DevTools extension, defaults to false.
  static bool devToolsEnabled = false;

  /// Whether to track the previous value of the signal, defaults to true.
  static bool trackPreviousValue = true;

  /// {@macro Resource.useRefreshing}
  static bool useRefreshing = true;

  /// The list of observers.
  static final observers = <SolidartObserver>[];

  /// If you want nested effects to have their own independent behavior, you can
  /// set this to true so that the Reactive system creates a dependency chain
  /// for nested inner effects. Defaults to false.
  static bool detachEffects = false;
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
