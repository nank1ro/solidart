part of 'core.dart';

/// Backs the [ValueListenable]/[ValueNotifier] listener API shared by signals.
///
/// Each listener is bridged to a solidart [ObserveSignal.observe] observation,
/// so listeners participate in auto-disposal exactly like any other observer:
/// adding one keeps the signal alive, and removing the last one lets the signal
/// dispose itself when [SignalBase.autoDispose] is enabled.
class _SignalListeners<T> {
  _SignalListeners(this._signal);

  final SignalBase<T> _signal;
  final _observations = <VoidCallback, DisposeObservation>{};

  /// Whether any listener is currently registered.
  bool get hasListeners => _observations.isNotEmpty;

  /// Registers [listener]. Adding the same listener twice is a no-op.
  void add(VoidCallback listener) {
    _observations.putIfAbsent(
      listener,
      () => _signal.observe((_, _) => listener()),
    );
  }

  /// Unregisters [listener], stopping its observation. No-op if not registered.
  void remove(VoidCallback listener) {
    _observations.remove(listener)?.call();
  }

  /// Notifies every listener.
  void notify() {
    // Snapshot so a listener that adds/removes a listener while being notified
    // does not trigger a ConcurrentModificationError.
    for (final listener in _observations.keys.toList()) {
      listener();
    }
  }

  /// Stops every observation and clears the registry.
  void dispose() {
    for (final cleanup in _observations.values) {
      cleanup();
    }
    _observations.clear();
  }
}
