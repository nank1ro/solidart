// ignore: lines_longer_than_80_chars
// ignore_for_file: public_member_api_docs, parameter_assignments, library_private_types_in_public_api
part of 'core.dart';

typedef ReactionErrorHandler = void Function(
  Object error,
  ReactionInterface reaction,
);

class ReactiveName {
  factory ReactiveName() => _instance;
  ReactiveName._internal();
  static final _instance = ReactiveName._internal();

  int nextIdCounter = 0;

  int get nextId => ++nextIdCounter;

  static String nameFor(String prefix) {
    assert(prefix.isNotEmpty, 'the prefix cannot be empty');
    return '$prefix@${_instance.nextId}';
  }
}

@protected
final reactiveSystem = ReactiveSystem();

class ReactiveSystem extends alien.ReactiveSystem<_Computed<dynamic>> {
  alien.Subscriber? activeSub;
  alien.Subscriber? activeScope;
  int batchDepth = 0;
  final pauseStack = <alien.Subscriber?>[];

  @override
  bool notifyEffect(alien.Subscriber effect) {
    final flags = effect.flags;
    if ((flags & alien.SubscriberFlags.dirty) != 0 ||
        ((flags & alien.SubscriberFlags.pendingComputed) != 0 &&
            updateDirtyFlag(effect, flags))) {
      (effect as _AlienEffect).run();
    } else {
      processPendingInnerEffects(effect, effect.flags);
    }
    return true;
  }

  @override
  bool updateComputed(_Computed<dynamic> computed) {
    final prevSub = activeSub;
    activeSub = computed;
    startTracking(computed);
    try {
      return computed.notify();
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

  void runEffect(_Effect effect) {
    final prevSub = activeSub;
    activeSub = effect;
    startTracking(effect);
    try {
      effect.fn();
    } finally {
      activeSub = prevSub;
      endTracking(effect);
    }
  }

  void runEffectScope(preset.EffectScope scope, void Function() fn) {
    final prevSub = activeScope;
    activeScope = scope;
    startTracking(scope);
    try {
      fn();
    } finally {
      activeScope = prevSub;
      endTracking(scope);
    }
  }

  void pauseTracking() {
    pauseStack.add(activeSub);
    activeSub = null;
  }

  void resumeTracking() {
    try {
      activeSub = pauseStack.removeLast();
    } catch (_) {
      activeSub = null;
    }
  }
}
