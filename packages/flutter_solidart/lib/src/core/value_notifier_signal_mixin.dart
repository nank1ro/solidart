import 'package:flutter/widgets.dart';
import 'package:solidart/solidart.dart' as solidart;

/// [ValueNotifier] implementation for [solidart.Signal]
mixin ValueNotifierSignalMixin<T> on solidart.Signal<T>
    implements ValueNotifier<T> {
  final _listeners = <VoidCallback, solidart.DisposeObservation>{};

  /// If true, the callback will be run when the listener is added
  bool get fireImmediately => false;

  @override
  void addListener(VoidCallback listener) {
    _listeners.putIfAbsent(listener, () {
      return observe((_, __) {
        listener();
      }, fireImmediately: fireImmediately);
    });
  }

  @override
  void removeListener(VoidCallback listener) {
    final cleanup = _listeners.remove(listener);
    cleanup?.call();
  }

  @override
  bool get hasListeners => _listeners.isNotEmpty;

  @override
  void notifyListeners() {
    shouldUpdate(force: true);
  }

  @override
  void dispose() {
    super.dispose();
    _listeners.clear();
  }
}
