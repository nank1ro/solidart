import 'dart:async';

import 'package:solidart/solidart.dart';

/// Extension that adds the `until` method to [SignalBase] classes.
extension Until<T> on SignalBase<T> {
  /// Returns the future that completes when the [condition] evalutes to true.
  /// If the [condition] is already true, it completes immediately.
  ///
  /// The [timeout] parameter specifies the maximum time to wait for the
  /// condition to be met. If provided and the timeout is reached before the
  /// condition is met, the future will complete with a [TimeoutException].
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
    }

    effect = Effect(
      () {
        if (condition(value)) {
          dispose();
          completer.complete(value);
        }
      },
      autoDispose: false,
    );

    // Start timeout timer if specified
    if (timeout != null) {
      timer = Timer(timeout, () {
        if (!completer.isCompleted) {
          dispose();
          completer.completeError(TimeoutException(null, timeout));
        }
      });
    }

    return completer.future;
  }
}
