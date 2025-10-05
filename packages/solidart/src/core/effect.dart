import 'package:alien_signals/alien_signals.dart' as alien;
import 'package:alien_signals/preset_developer.dart' as alien;

import 'config.dart';
import 'disposable.dart';

abstract interface class Effect implements Disposable {}

class SolidartEffect extends alien.PresetEffect
    with AutoDisposable
    implements Effect {
  SolidartEffect(void Function() callback, {bool? autoDispose})
      : autoDispose = autoDispose ?? SolidartConfig.autoDispose,
        super(callback: callback) {
    final prevSub = alien.setActiveSub(this);
    if (prevSub != null) {
      alien.system.link(this, prevSub, 0);
    }

    try {
      callback();
    } finally {
      alien.setActiveSub(prevSub);
    }
  }

  @override
  final bool autoDispose;

  @override
  bool disposed = false;

  @override
  void dispose() {
    if (disposed) return;

    disposed = true;
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
}
