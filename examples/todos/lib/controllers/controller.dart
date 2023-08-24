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
  }) : _todos = createSignal(initialTodos);

  // Keep the editable todos signal private
  // only the TodoController can mutate the value.
  final Signal<List<Todo>> _todos;

  /// Expose the whole list of todos as a ReadSignal so the
  /// user cannot mutate directly the object.
  late final todos = _todos.toReadSignal();

  /// The list of completed todos
  late final completedTodos = createComputed(
    () => _todos().where((todo) => todo.completed).toList(),
  );

  /// The list of incomplete todos
  late final incompleteTodos = createComputed(
    () => _todos().where((todo) => !todo.completed).toList(),
  );

  /// Add a todo
  void add(Todo todo) {
    _todos.update((value) => [...value, todo]);
  }

  /// Remove a todo with the given [id]
  void remove(String id) {
    _todos.update(
      (value) => value.where((todo) => todo.id != id).toList(),
    );
  }

  /// Toggle a todo with the given [id]
  void toggle(String id) {
    _todos.update(
      (value) => [
        for (final todo in value)
          if (todo.id != id) todo else todo.copyWith(completed: !todo.completed)
      ],
    );
  }

  void dispose() {
    todos.dispose();
    completedTodos.dispose();
    incompleteTodos.dispose();
  }
}
