part of '../solidart.dart';

/// Common configuration for signals.
abstract interface class SignalConfiguration<T> implements Configuration {
  /// Comparator used to skip equal updates.
  ///
  /// When it returns `true`, the new value is treated as equal and the update
  /// is skipped.
  ValueComparator<T> get equals;

  /// Whether to report to DevTools.
  bool get trackInDevTools;

  /// Whether to track previous values.
  ///
  /// Previous values are captured on successful updates after a tracked read.
  bool get trackPreviousValue;
}
