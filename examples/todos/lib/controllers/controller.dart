import 'package:flutter/foundation.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:todos/models/todo.dart';

/// Contains the state of the [todos] list and allows to
/// - `add`: Add a todo in the list of [todos]
/// - `remove`: Removes a todo with the given id from the list of [todos]
/// - `toggle`: Toggles a todo with the given id
/// The list of todos exposed is a [ReadSignal] so the user cannot mutate
/// the signal without using this controller.
@immutable
class TodosController {
  TodosController({
    List<Todo> initialTodos = const [],
  }) : todos = ListSignal(initialTodos);

  // Keep the editable todos signal private
  // only the TodoController can mutate the value.
  final ListSignal<Todo> todos;

  /// The list of completed todos
  late final completedTodos = createComputed(
    () => todos.where((todo) => todo.completed).toList(),
  );

  /// The list of incomplete todos
  late final incompleteTodos = createComputed(
    () => todos.where((todo) => !todo.completed).toList(),
  );

  /// Add a todo
  void add(Todo todo) {
    todos.add(todo);
  }

  /// Remove a todo with the given [id]
  void remove(String id) {
    todos.removeWhere((todo) => todo.id == id);
  }

  /// Toggle a todo with the given [id]
  void toggle(String id) {
    final todoIndex = todos.indexWhere((element) => element.id == id);
    final todo = todos[todoIndex];
    todos[todoIndex] = todo.copyWith(completed: !todo.completed);
  }

  void dispose() {
    todos.dispose();
    completedTodos.dispose();
    incompleteTodos.dispose();
  }
}
