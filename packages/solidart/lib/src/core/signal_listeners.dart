part of 'core.dart';

/// Backs the [ValueListenable]/[ValueNotifier] listener API shared by signals.
///
/// Like [ChangeNotifier], each [add] call is a separate registration and each
/// [remove] call removes one registration. Listener errors are reported to
/// [Listenable.onError] instead of being thrown.
///
/// Each registration is bridged to its own solidart observation (like
/// [ObserveSignal.observe], but without reading the previous value), so
/// listeners participate in auto-disposal exactly like any other observer:
/// adding one keeps the signal alive, and removing the last one lets the
/// signal dispose itself when [SignalBase.autoDispose] is enabled.
///
/// A listener that writes the signal it listens to is not notified of its own
/// write, following solidart's effect re-entrancy rule. Writes inside a
/// [batch] notify at most once, at the end of the batch. A
/// [Signal.notifyListeners] call made from inside a listener does not call
/// that listener again. Listeners that have not run yet in the current
/// notification run once, and other listeners that already ran are called
/// again.
class _SignalListeners<T> {
  _SignalListeners(this._signal);

  final SignalBase<T> _signal;
  final _observations = <(VoidCallback, DisposeObservation)>[];

  /// Whether any listener is currently registered.
  bool get hasListeners => _observations.isNotEmpty;

  /// Registers [listener] with a new observation. Adding the same listener
  /// twice registers it twice. No-op if the signal is disposed.
  ///
  /// The observation is created untracked, so a listener added inside a
  /// running effect or computed does not become its child.
  void add(VoidCallback listener) {
    if (_signal.disposed) return;
    final observation = untracked(
      // A listener takes no arguments, so it must not build the history.
      () => _signal._observeChanges(() {
        try {
          listener();
        } catch (error, stack) {
          Listenable.onError(error, stack, ErrorContext.listener);
        }
      }),
    );
    _observations.add((listener, observation));
  }

  /// Unregisters one registration of [listener], stopping its observation.
  /// No-op if not registered.
  void remove(VoidCallback listener) {
    final index = _observations.indexWhere((entry) => entry.$1 == listener);
    if (index == -1) return;
    _observations.removeAt(index).$2();
  }

  /// Stops every observation and clears the registry.
  void dispose() {
    for (final (_, cleanup) in _observations) {
      cleanup();
    }
    _observations.clear();
  }
}
