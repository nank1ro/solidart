import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

@immutable
class Todo {
  const Todo({
    required this.id,
    required this.task,
    required this.completed,
  });

  factory Todo.create(String task) {
    final uuid = const Uuid().v4();
    return Todo(id: uuid, task: task, completed: false);
  }

  final String id;
  final String task;
  final bool completed;

  static List<Todo> get sample {
    return [
      Todo.create('Learn solidart'),
      Todo.create('Wash the car'),
      Todo.create('Go shopping'),
    ];
  }

  Todo copyWith({bool? completed}) {
    return Todo(
      id: id,
      task: task,
      completed: completed ?? this.completed,
    );
  }

  @override
  String toString() => 'Todo(id: $id, task: $task, completed: $completed)';
}

enum TodosFilter { all, incomplete, completed }
