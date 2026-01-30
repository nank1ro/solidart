part of '../solidart.dart';

/// Batches signal updates and flushes once at the end.
///
/// Nested batches are supported; the final flush happens when the outermost
/// batch completes.
///
/// ```dart
/// final a = Signal(1);
/// final b = Signal(2);
/// Effect(() => print('sum: ${a.value + b.value}'));
///
/// batch(() {
///   a.value = 3;
///   b.value = 4;
/// });
/// ```
T batch<T>(T Function() fn) {
  preset.startBatch();
  try {
    return fn();
  } finally {
    preset.endBatch();
  }
}
