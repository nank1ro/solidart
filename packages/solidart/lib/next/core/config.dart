import 'package:solidart/next/core/observer.dart';

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

  // coverage:ignore-start
  /// Whether to assert that SignalBuilder has at least one dependency during
  /// its build. Defaults to true.
  ///
  /// If you set this to false, you must ensure that the SignalBuilder has at
  /// least one dependency, otherwise it won't rebuild when the signals change.
  ///
  /// The ability to disable this assertion is provided for advanced use cases
  /// where you might have a SignalBuilder that builds something based on
  /// disposed signals where you might be interested in their latest values.
  static bool assertSignalBuilderWithoutDependencies = true;
  // coverage:ignore-end

  /// The list of observers.
  static final observers = <SolidartObserver>[];

  /// If you want nested effects to have their own independent behavior, you can
  /// set this to true so that the Reactive system creates a dependency chain
  /// for nested inner effects. Defaults to false.
  static bool detachEffects = false;
}
