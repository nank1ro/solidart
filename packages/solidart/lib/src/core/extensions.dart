part of 'core.dart';

/// Adds the [toggle] method to boolean signals
extension ToggleBoolSignal on Signal<bool> {
  /// Toggles the signal boolean value.
  void toggle() => value = !value;
}

/// A callback that is fired when the signal value changes
extension ObserveSignal<T> on SignalBase<T> {
  /// Observe the signal and trigger the [listener] every time the value changes
  DisposeObservation observe(
    ObserveCallback<T> listener, {
    bool fireImmediately = false,
  }) {
    var skipped = false;
    final disposeEffect = Effect(() {
      // Wait for a value (a lazy signal, or a subclass or test double that
      // reports no value). The tracked read makes this effect rerun when a
      // value arrives. Skip a Computed (hasValue evaluates the selector) and a
      // Resource (it always has a state, and reading hasValue before value
      // would subscribe before a lazy Resource resolves).
      if (this is! Computed && this is! Resource && !hasValue) {
        skipped = true;
        return;
      }
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

    return () {
      disposeEffect();
      _mayDispose();
    };
  }
}
