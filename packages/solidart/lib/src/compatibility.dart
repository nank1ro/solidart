// ignore_for_file: public_member_api_docs

import 'package:solidart/src/effect.dart';
import 'package:solidart/src/signal.dart';
import 'package:solidart/src/utils.dart';

typedef SignalBase<T> = ReadonlySignal<T>;
typedef ReadSignal<T> = ReadonlySignal<T>;
typedef DisposeEffect = void Function();

extension SolidartSignalCall<T> on ReadonlySignal<T> {
  T call() => value;
}

extension BooleanSignalOpers on Signal<bool> {
  void toggle() => value = !value;
}

/// A callback that is fired when the signal value changes
extension ObserveSignal<T> on ReadonlySignal<T> {
  /// Observe the signal and trigger the [listener] every time the value changes
  void Function() observe(
    void Function(T? previousValue, T value) listener, {
    bool fireImmediately = false,
  }) {
    var skipped = false;
    final effect = Effect(() {
      // Tracks the value
      value;
      if (!fireImmediately && !skipped) {
        skipped = true;
        return;
      }
      untracked(() {
        listener(untrackedPreviousValue, untrackedValue);
      });
    });

    return effect.dispose;
  }
}

extension DisposeEffectCall on Effect {
  void call() => dispose();
}
