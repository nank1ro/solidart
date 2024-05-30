part of 'core.dart';

/// Execute a callback that will not side-effect until its top-most batch is
/// completed.
///
/// Example:
/// ```dart
/// final x = Signal(10);
/// final y = Signal(20);
///
/// Effect((_) => print('x = ${x.value}, y = ${y.value}'));
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
T batch<T>(T Function() fn) {
  final context = ReactiveContext.main;
  final prevDerivation = context.startUntracked();
  context.startBatch();

  try {
    return fn();
  } finally {
    context
      ..endBatch()
      ..endUntracked(prevDerivation);
  }
}
