// ignore_for_file: public_member_api_docs

import 'package:alien_signals/alien_signals.dart' as alien;
import 'package:alien_signals/preset_developer.dart' as alien;
// TODO: wait alien_signal export
// ignore: implementation_imports
import 'package:alien_signals/src/preset.dart' as alien show flush;
import 'package:alien_signals/system.dart' as alien;
import 'package:solidart/src/signal.dart';

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
