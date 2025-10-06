import 'dart:async';

import 'package:alien_signals/alien_signals.dart' as alien;
import 'package:alien_signals/preset_developer.dart' as alien;

import '_internal.dart';
import 'config.dart';
import 'debuggable.dart';
import 'disposable.dart';

abstract interface class Effect implements Disposable, Debuggable {
  factory Effect(void Function() callback,
      {bool? autoDispose,
      String? debugLabel,
      bool? autorun,
      Duration? delay}) = SolidartEffect;

  void run();
}

class SolidartEffect extends alien.PresetEffect
    with AutoDisposable
    implements Effect {
  SolidartEffect(void Function() callback,
      {bool? autoDispose,
      String? debugLabel,
      bool? autorun,
      Duration? delay,
      bool? detach})
      : autoDispose = autoDispose ?? SolidartConfig.autoDispose,
        debugLabel = createDebugLabel(debugLabel),
        super(callback: callback) {
    // Create an effect and get the prevSub immediately to avoid linking
    // to the wrong prevSub due to delays.
    final prevSub = alien.getActiveSub();
    void init() {
      timer = null;
      if (prevSub != null &&
          (detach ?? SolidartConfig.detachEffects) == false) {
        alien.system.link(this, prevSub, 0);
      }
      if (autorun == true) run();
    }

    if (delay == null) {
      init();
      return;
    }

    timer = Timer(delay, init);
  }

  @override
  final bool autoDispose;

  @override
  final String debugLabel;

  Timer? timer;

  @override
  bool disposed = false;

  @override
  void dispose() {
    if (disposed) return;

    disposed = true;
    timer?.cancel();

    for (var link = subs; link != null; link = link.nextSub) {
      if (link.sub case final AutoDisposable disposable) {
        disposable.maybeDispose();
      }
    }

    final deps = <AutoDisposable>[];
    for (var link = this.deps; link != null; link = link.nextDep) {
      if (link.dep case final AutoDisposable disposable) {
        deps.add(disposable);
      }
    }

    super.dispose();
    deps.forEach((dep) => dep.maybeDispose());
  }

  @override
  void run() {
    final prevSub = alien.setActiveSub(this);
    try {
      callback();
    } finally {
      alien.setActiveSub(prevSub);
    }
  }
}
