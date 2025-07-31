part of 'core.dart';

/// Execute a callback that will not be tracked by the reactive system.
///
/// This can be useful inside Effects or Observations to prevent a signal from
/// being tracked.
T untracked<T>(T Function() callback) {
  final prevSub = reactiveSystem.setCurrentSub(null);
  try {
    return callback();
  } finally {
    reactiveSystem.setCurrentSub(prevSub);
  }
}
