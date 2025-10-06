import 'package:alien_signals/alien_signals.dart' as alien;
import 'package:alien_signals/preset_developer.dart' as alien;
import 'package:alien_signals/src/preset.dart' as alien show flush;
import 'package:alien_signals/system.dart' as alien;

import '../core/signal.dart';

mixin Reactive<T> on SolidartSignal<T> {
  bool dirty = false;

  void trigger() {
    dirty = true;
    flags = 17 /* Mutable | Dirty */;
    if (subs case final alien.Link link) {
      alien.system.propagate(link);
      if (alien.getBatchDepth() == 0) alien.flush();
    }
  }

  @override
  bool update() {
    final result = super.update();
    if (dirty) {
      dirty = false;
      return true;
    }

    return result;
  }
}
