// ignore_for_file: public_member_api_docs
//
// Reactive flags map: https://github.com/medz/alien-signals-dart/blob/main/flags.md
part of 'core.dart';

extension MayDisposeDependencies on system.ReactiveNode {
  Iterable<system.ReactiveNode> getDependencies() {
    var link = deps;
    final foundDeps = <system.ReactiveNode>{};
    for (; link != null; link = link.nextDep) {
      foundDeps.add(link.dep);
    }
    return foundDeps;
  }

  void mayDisposeDependencies([Iterable<system.ReactiveNode>? include]) {
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
