part of '../solidart.dart';

/// {@template solidart.config}
/// Global configuration for v3 reactive primitives.
///
/// These flags provide defaults for newly created signals/effects/resources.
/// You can override them per-instance via constructor parameters.
/// {@endtemplate}
final class SolidartConfig {
  const SolidartConfig._(); // coverage:ignore-line

  /// Whether nodes auto-dispose when they lose all subscribers.
  ///
  /// When enabled, signals/computeds/effects may dispose themselves once
  /// nothing depends on them.
  static bool autoDispose = false;

  /// Whether nested effects detach from parent subscriptions.
  ///
  /// When `true`, inner effects do not become dependencies of their parent
  /// effect unless explicitly linked.
  static bool detachEffects = false;

  /// Whether to track previous values by default.
  ///
  /// Previous values are captured only after a signal has been read at least
  /// once.
  static bool trackPreviousValue = true;

  /// Whether to keep values while refreshing resources.
  ///
  /// When `true`, a refresh marks the state as `isRefreshing` instead of
  /// replacing it with `loading`.
  static bool useRefreshing = true;

  /// Whether DevTools tracking is enabled.
  ///
  /// Signals only emit DevTools events when both this flag and
  /// `trackInDevTools` are `true`.
  static bool devToolsEnabled = false;

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

  /// Registered observers for signal lifecycle events.
  ///
  /// Observers are notified only when `trackInDevTools` is enabled for the
  /// signal instance.
  static final observers = <SolidartObserver>[];
}
