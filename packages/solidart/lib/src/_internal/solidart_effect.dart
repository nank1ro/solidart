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
    Duration? delay,
  })  : autoDispose = autoDispose ?? SolidartConfig.autoDispose,
        name = name ?? nameFor('Effect'),
        super(callback: callback) {
    if (delay != null) {
      timer = Timer(delay, () => _init(detach: detach, autorun: autorun));
      return;
    }

    _init(detach: detach, autorun: autorun);
  }

  void _init({bool? detach, bool? autorun}) {
    if (detach != true) {
      final prevSub = alien.getActiveSub();
      if (prevSub != null) {
        alien.system.link(this, prevSub, 0);
      }
    }
    if (autorun ?? true) run();
  }

  Timer? timer;
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

    timer?.cancel();
    isDisposed = true;
    final deps = <Disposable>[];

    for (var link = this.deps; link != null; link = link.nextDep) {
      if (link.dep case final Disposable disposable) {
        deps.add(disposable);
      }
    }

    for (final callback in callbacks) {
      callback();
    }

    callbacks.clear();
    super.dispose();

    for (final dep in deps) {
      dep.maybeDispose();
    }
  }

  @override
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  void maybeDispose() {
    if (autoDispose) dispose();
  }
}
