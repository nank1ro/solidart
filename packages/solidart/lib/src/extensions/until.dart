part of '../solidart.dart';

/// Waits until a signal satisfies a condition.
extension UntilSignal<T> on ReadonlySignal<T> {
  /// Returns a future that completes when [condition] becomes true.
  ///
  /// If [condition] is already true, this returns the current value
  /// immediately.
  ///
  /// When [timeout] is provided, the returned future completes with a
  /// [TimeoutException] if the condition is not met in time.
  FutureOr<T> until(
    bool Function(T value) condition, {
    Duration? timeout,
  }) {
    if (condition(value)) return value;

    final completer = Completer<T>();
    Timer? timer;
    late final Effect effect;

    void dispose() {
      effect.dispose();
      timer?.cancel();
      timer = null;
    }

    effect = Effect(
      () {
        final current = value;
        if (!condition(current)) return;
        dispose();
        if (!completer.isCompleted) {
          completer.complete(current);
        }
      },
      autoDispose: false,
    );

    onDispose(dispose);

    if (timeout != null) {
      timer = Timer(timeout, () {
        if (completer.isCompleted) return;
        dispose();
        completer.completeError(TimeoutException(null, timeout));
      });
    }

    return completer.future;
  }
}
