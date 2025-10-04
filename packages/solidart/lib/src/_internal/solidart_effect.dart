// ignore_for_file: public_member_api_docs

part of '../effect.dart';

class SolidartEffect extends alien.PresetEffect implements Effect, Disposable {
  SolidartEffect(
    void Function() callback, {
    this.onError,
    String? name,
    bool? autoDispose,
    bool? detach,
    bool? autorun,
  })  : autoDispose = autoDispose ?? SolidartConfig.autoDispose,
        name = name ?? nameFor('Effect'),
        super(callback: callback) {
    if (detach != true) {
      final sub = alien.setActiveSub(null);
      if (sub != null) {
        alien.system.link(this, sub, 0);
      }
    }

    if (autorun ?? true) run();
  }

  final void Function(Object? error)? onError;

  @override
  final String name;

  @override
  final bool autoDispose;

  @override
  bool get disposed => isDisposed;

  @override
  bool isDisposed = false;

  late final callbacks = <void Function()>[];

  @override
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  void onDispose(void Function() callback) {
    if (isDisposed) return;
    callbacks.add(callback);
  }

  @override
  void run() {
    if (isDisposed) return;

    final prevSub = alien.setActiveSub(this);
    try {
      callback();
    } catch (e) {
      if (onError == null) {
        rethrow;
      }

      onError!(e);
    } finally {
      alien.setActiveSub(prevSub);
    }
  }

  @override
  void dispose() {
    if (isDisposed) return;

    isDisposed = true;
    for (final callback in callbacks) {
      callback();
    }
    callbacks.clear();

    super.dispose();
  }

  @override
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  void maybeDispose() {
    if (autoDispose) dispose();
  }
}
