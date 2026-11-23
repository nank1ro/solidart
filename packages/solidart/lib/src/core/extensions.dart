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
      // Only a readable signal can lack a value (a lazy signal, or a subclass
      // that reports no value). The tracked read makes this effect rerun when
      // a value arrives. Never read hasValue on a Computed (it evaluates the
      // selector) or untracked (it would evaluate sources before this effect
      // subscribes).
      final self = this;
      if (self is ReadableSignal<T> && !self.hasValue) {
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
