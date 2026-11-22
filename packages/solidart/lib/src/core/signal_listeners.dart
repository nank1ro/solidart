part of 'core.dart';

/// Backs the [ValueListenable]/[ValueNotifier] listener API shared by signals.
///
/// Like [ChangeNotifier], each [add] call is a separate registration and each
/// [remove] call removes one registration. Listener errors are reported to
/// [Listenable.onError] instead of being thrown.
///
/// Each registration is backed by its own [Effect], so listeners participate
/// in auto-disposal like other observers: adding one keeps the signal alive,
/// and removing the last one lets the signal dispose itself when
/// [SignalBase.autoDispose] is enabled.
///
/// A listener that writes the signal it listens to is not notified of its own
/// write, following solidart's effect re-entrancy rule.
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
    var initialRun = true;
    final disposeEffect = untracked(
      () => Effect(() {
        final shouldNotify = !initialRun;
        initialRun = false;

        // hasValue tracks a lazy signal even before its value can be read.
        if (_signal case ReadableSignal<T>(hasValue: false)) return;
        _signal.value;
        if (!shouldNotify) return;

        untracked(() {
          try {
            listener();
          } catch (error, stack) {
            Listenable.onError(error, stack, ErrorContext.listener);
          }
        });
      }),
    );
    _observations.add((
      listener,
      () {
        disposeEffect();
        _signal._mayDispose();
      },
    ));
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
