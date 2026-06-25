// ignore_for_file: public_member_api_docs, library_private_types_in_public_api
//
// Reactive flags map: https://github.com/medz/alien-signals-dart/blob/main/flags.md
part of 'core.dart';

const _hasChildEffect = 64 as alien_system.ReactiveFlags;

extension MayDisposeDependencies on alien_system.ReactiveNode {
  Iterable<alien_system.ReactiveNode> getDependencies() {
    var link = deps;
    final foundDeps = <alien_system.ReactiveNode>{};
    for (; link != null; link = link.nextDep) {
      foundDeps.add(link.dep);
    }
    return foundDeps;
  }

  void mayDisposeDependencies([Iterable<alien_system.ReactiveNode>? include]) {
    final dependencies = {...getDependencies(), ...?include};
    for (final dep in dependencies) {
      switch (dep) {
        case _AlienSignal():
          dep.parent._mayDispose();
        case _AlienComputed():
          dep.parent._mayDispose();
      }
    }
  }
}

typedef ReactionErrorHandler =
    void Function(Object error, ReactionInterface reaction);

class ReactiveName {
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

class ReactiveSystem {
  int get batchDepth => alien.getBatchDepth();

  alien_system.ReactiveNode? get activeSub => alien.getActiveSub();

  set activeSub(alien_system.ReactiveNode? sub) {
    alien.setActiveSub(sub);
  }

  alien_system.ReactiveNode? setCurrentSub(alien_system.ReactiveNode? sub) {
    return alien.setActiveSub(sub);
  }

  void startBatch() => alien.startBatch();

  void endBatch() => alien.endBatch();

  void link(alien_system.ReactiveNode dep, alien_system.ReactiveNode sub) {
    alien.link(dep, sub, alien.cycle);
  }

  T getComputedValue<T>(_AlienComputed<T> computed) {
    if ((computed.flags & alien_system.ReactiveFlags.pending) !=
            alien_system.ReactiveFlags.none &&
        computed.deps == null) {
      computed.flags &= ~alien_system.ReactiveFlags.pending;
    }

    return computed.get();
  }

  Option<T> getSignalValue<T>(_AlienSignal<T> signal) {
    return signal.get();
  }

  void setSignalValue<T>(_AlienSignal<T> signal, Option<T> value) {
    signal.set(value);
  }

  void stopEffect(alien_system.ReactiveNode effect) {
    alien.stop(effect);
  }

  void runEffect(_AlienEffect effect) {
    alien.run(effect);
  }

  void propagate(alien_system.Link link) {
    alien.propagate(link, alien.runDepth > 0);
  }

  void flush() => alien.flush();
}
