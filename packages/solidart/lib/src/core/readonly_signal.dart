part of '../solidart.dart';

/// Read-only reactive value.
///
/// Reading [value] establishes a dependency; [untrackedValue] does not.
/// This interface is implemented by [Signal], [Computed], and [Resource].
///
/// ```dart
/// final count = Signal(0);
/// ReadonlySignal<int> readonly = count.toReadonly();
/// ```
// TODO(nank1ro): Maybe rename to `ReadSignal`? medz: I still recommend `ReadonlySignal` because it is semantically clearer., https://github.com/nank1ro/solidart/pull/166#issuecomment-3623175977
abstract interface class ReadonlySignal<T>
    implements system.ReactiveNode, Disposable, SignalConfiguration<T> {
  /// Returns the previous value (tracked read).
  ///
  /// This may return `null` if tracking is disabled or the signal has not been
  /// read since the last update.
  T? get previousValue;

  /// Returns the previous value without tracking.
  T? get untrackedPreviousValue;

  /// Returns the current value without tracking.
  T get untrackedValue;

  /// Returns the current value and tracks dependencies.
  T get value;

  /// Returns [value]. This allows using a signal as a callable.
  T call();
}
