import '../core/debuggable.dart';

sealed class Node implements Debuggable {
  String get type;

  Map<String, dynamic> toJson();
}

abstract interface class SignalNode implements Node {
  bool get lazy;
  Object get value;
  Iterable<Node> get subscribers;
}

abstract interface class EffectNode implements Node {
  Iterable<Node> get dependencies;
}

abstract interface class ComputationNode implements Node {
  Object get value;
  Iterable<Node> get dependencies;
  Iterable<Node> get subscribers;
}
