part of '../solidart.dart';

/// Observes [ReadonlySignal] changes with previous and current values.
extension ObserveSignal<T> on ReadonlySignal<T> {
  /// Observe the signal and invoke [listener] whenever the value changes.
  ///
  /// When [fireImmediately] is `true`, the listener runs once on subscription.
  /// Returns a disposer that stops the observation.
  DisposeObservation observe(
    ObserveCallback<T> listener, {
    bool fireImmediately = false,
  }) {
    var skipped = false;
    final effect = Effect(
      () {
        value;
        if (!fireImmediately && !skipped) {
          skipped = true;
          return;
        }
        untracked(() {
          listener(untrackedPreviousValue, untrackedValue);
        });
      },
      detach: true,
    );

    return effect.dispose;
  }
}
