// ignore_for_file: public_member_api_docs

part of 'core.dart';

final system = ReactiveSystem();

class ReactiveSystem extends alien.ReactiveSystem<Computed<dynamic>> {
  alien.Subscriber? activeSub;
  int batchDepth = 0;

  @override
  bool notifyEffect(alien.Subscriber effect) {
    if (effect is Effect) {
      effect._schedule();
      return true;
    }
    return false;
  }

  @override
  bool updateComputed(Computed<dynamic> computed) {
    return computed._update();
  }

  void linkDep(alien.Dependency dep) {
    if (activeSub != null) link(dep, activeSub!);
  }

  void disposeSub(alien.Subscriber sub) {
    startTracking(sub);
    endTracking(sub);
  }

  T untrack<T>(T Function() fn) {
    final prevSub = activeSub;
    activeSub = null;
    try {
      return fn();
    } finally {
      activeSub = prevSub;
    }
  }
}
