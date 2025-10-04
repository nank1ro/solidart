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
