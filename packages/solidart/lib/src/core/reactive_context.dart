// ignore_for_file: public_member_api_docs
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
