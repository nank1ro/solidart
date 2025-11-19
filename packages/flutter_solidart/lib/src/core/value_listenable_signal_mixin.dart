// coverage:ignore-file
import 'package:flutter/foundation.dart';
import 'package:solidart/solidart.dart' as solidart;

/// [ValueNotifier] implementation for [solidart.Signal]
mixin ValueListenableSignalMixin<T> on solidart.ReadSignal<T>
    implements ValueListenable<T> {
  final _listeners = <VoidCallback, solidart.DisposeObservation>{};

  /// If true, the callback will be run when the listener is added
  bool get fireImmediately => false;

  @override
  void addListener(VoidCallback listener) {
    _listeners.putIfAbsent(listener, () {
      return observe((_, _) {
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
  void dispose() {
    super.dispose();
    for (final cleanup in _listeners.values) {
      cleanup();
    }
    _listeners.clear();
  }
}
