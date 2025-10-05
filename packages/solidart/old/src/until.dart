// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'package:solidart/src/effect.dart';
import 'package:solidart/src/signal.dart';

extension Until<T> on ReadonlySignal<T> {
  /// Returns the future that completes when the [condition] evalutes to true.
  /// If the [condition] is already true, it completes immediately.
  ///
  /// The [timeout] parameter specifies the maximum time to wait for the
  /// condition to be met. If provided and the timeout is reached before the
  /// condition is met, the future will complete with a [TimeoutException].
  FutureOr<T> until(bool Function(T value) condition,
      {Duration? timeout}) async {
    final locals = value;
    if (condition(locals)) return locals;

    Timer? timer;
    late final Effect effect;
    final completer = Completer<T>();

    effect = Effect(() {
      if (condition(value)) {
        timer?.cancel();
        effect.dispose();
        return completer.complete(value);
      }
    }, autoDispose: false);

    if (timeout != null) {
      timer = Timer(timeout, () {
        if (completer.isCompleted) return;
        effect.dispose();

        final locals = value;
        if (condition(locals)) {
          return completer.complete(locals);
        }

        completer.completeError(TimeoutException(null, timeout));
      });
    }

    return completer.future;
  }
}
