part of '../solidart.dart';

/// Runs [callback] without tracking dependencies.
///
/// This is useful when you want to read or write signals inside an effect
/// without establishing a dependency.
///
/// ```dart
/// final count = Signal(0);
/// Effect(() {
///   print(count.value);
///   untracked(() => count.value = count.value + 1);
/// });
/// ```
T untracked<T>(T Function() callback) {
  final prevSub = preset.setActiveSub();
  try {
    return callback();
  } finally {
    preset.setActiveSub(prevSub);
  }
}
