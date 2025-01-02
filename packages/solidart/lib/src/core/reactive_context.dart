// ignore_for_file: public_member_api_docs
part of 'core.dart';

class _ReactiveState {
  /// Monotonically increasing counter for assigning a name to an action/reaction/atom
  int nextIdCounter = 0;
}

typedef ReactionErrorHandler = void Function(
  Object error,
  ReactionInterface reaction,
);

/// Configuration used by [ReactiveContext]
@internal
class ReactiveConfig {
  ReactiveConfig({
    this.maxIterations = 100,
  });

  /// The main or default configuration used by [ReactiveContext]
  static final ReactiveConfig main = ReactiveConfig();

  /// Max number of iterations before bailing out for a cyclic reaction
  final int maxIterations;
}

class ReactiveContext {
  ReactiveContext._main();

  /// The main reactive context
  static final ReactiveContext main = ReactiveContext._main();
  final config = ReactiveConfig.main;

  final _state = _ReactiveState();

  int get nextId => ++_state.nextIdCounter;

  String nameFor(String prefix) {
    assert(prefix.isNotEmpty, 'the prefix cannot be empty');
    return '$prefix@$nextId';
  }
}
