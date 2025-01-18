// ignore_for_file: public_member_api_docs

part of 'core.dart';

final system = ReactiveSystem();

class ReactiveSystem extends alien.ReactiveSystem<Computed<dynamic>> {
  alien.Subscriber? activeSub;
  alien.Subscriber? activeScope;
  int batchDepth = 0;

  @override
  bool notifyEffect(alien.Subscriber effect) {
    final flags = effect.flags;
    if ((flags & alien.SubscriberFlags.dirty) != 0 ||
        ((flags & alien.SubscriberFlags.pendingComputed) != 0 &&
            updateDirtyFlag(effect, flags))) {
      (effect as Effect)._run();
    } else {
      processPendingInnerEffects(effect, effect.flags);
    }
    return true;
  }

  @override
  bool updateComputed(Computed<dynamic> computed) {
    final prevSub = activeSub;
    activeSub = computed;
    startTracking(computed);
    try {
      return computed._compute();
    } finally {
      activeSub = prevSub;
      endTracking(computed);
    }
  }

  void startBatch() {
    ++batchDepth;
  }

  void endBatch() {
    if ((--batchDepth) == 0) {
      processEffectNotifications();
    }
  }

  void disposeSub(alien.Subscriber sub) {
    startTracking(sub);
    endTracking(sub);
  }
}
