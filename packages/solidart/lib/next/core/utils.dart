import 'package:alien_signals/alien_signals.dart' as alien;

/// Execute a callback that will not side-effect until its top-most batch is
/// completed.
///
/// Example:
/// ```dart
/// final x = Signal(10);
/// final y = Signal(20);
///
/// Effect(() => print('x = ${x.value}, y = ${y.value}'));
/// // The Effect above prints 'x = 10, y = 20'
///
/// batch(() {
///   x.value++;
///   y.value++;
/// });
/// // The Effect above prints 'x = 11, y = 21'
/// ```
/// As you can see, the effect is not executed until the batch is completed.
/// So when `x` changes, the effect is paused and you never see it printing:
/// "x = 11, y = 20".
T batch<T>(T Function() callback) {
  alien.startBatch();
  try {
    return callback();
  } finally {
    alien.endBatch();
  }
}

/// Execute a callback that will not be tracked by the reactive system.
///
/// This can be useful inside Effects or Observations to prevent a signal from
/// being tracked.
T untracked<T>(T Function() callback) {
  final prevSub = alien.setActiveSub(null);
  try {
    return callback();
  } finally {
    alien.setActiveSub(prevSub);
  }
}
