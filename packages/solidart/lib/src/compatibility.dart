// ignore_for_file: public_member_api_docs

import 'package:solidart/src/effect.dart';
import 'package:solidart/src/signal.dart';
import 'package:solidart/src/utils.dart';

@Deprecated('Use ReadonlySignal instead')
typedef SignalBase<T> = ReadonlySignal<T>;

@Deprecated('Use ReadonlySignal instead')
typedef ReadSignal<T> = ReadonlySignal<T>;

@Deprecated('Use `void Function()` instead')
typedef DisposeEffect = void Function();

extension SolidartSignalCall<T> on ReadonlySignal<T> {
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  @Deprecated('Use .value instead')
  T call() => value;
}

extension BooleanSignalOpers on Signal<bool> {
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  void toggle() => value = !untrackedValue;
}

extension UpdatableSignalOpers<T> on Signal<T> {
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  void updateValue(T Function(T value) updates) {
    value = updates(untrackedValue);
  }
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
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  @Deprecated('Use .dispose() instead')
  void call() => dispose();
}
