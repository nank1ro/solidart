import 'package:flutter/foundation.dart';
import 'package:solidart/solidart.dart';

mixin SignalValueListenableMixin<T> on ReadonlySignal<T>
    implements ValueListenable<T> {
  final List<VoidCallback> _listeners = <VoidCallback>[];

  Effect? _effect;
  bool _skipped = false;
  bool _disposeAttached = false;

  void _ensureEffect() {
    if (_effect != null) return;
    _skipped = false;
    _effect = Effect(
      () {
        value;
        if (!_skipped) {
          _skipped = true;
          return;
        }
        if (_listeners.isEmpty) return;
        for (final callback in List<VoidCallback>.from(_listeners)) {
          callback();
        }
      },
      autoDispose: false,
      detach: true,
    );
    if (!_disposeAttached) {
      _disposeAttached = true;
      onDispose(() {
        _effect?.dispose();
        _effect = null;
        _listeners.clear();
      });
    }
  }

  @override
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
    _ensureEffect();
  }

  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
    if (_listeners.isEmpty) {
      _effect?.dispose();
      _effect = null;
    }
  }
}
