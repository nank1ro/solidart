import 'package:flutter/foundation.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:todos/models/todo.dart';

/// Contains the state of the [todos] list and allows to
/// - `add`: Add a todo in the list of [todos]
/// - `remove`: Removes a todo with the given id from the list of [todos]
/// - `toggle`: Toggles a todo with the given id
/// The list of todos exposed is a [ReadableSignal] so the user cannot mutate
/// the signal without using this controller.
@immutable
class TodosController {
  TodosController({
    List<Todo> initialTodos = const [],
  }) : _todos = createSignal(initialTodos);

  // Keep the editable todos signal private
  // only the TodoController can mutate the value.
  final Signal<List<Todo>> _todos;

  // Expose the list of todos as a ReadableSignal so the
  // user cannot mutate directly the object.
  ReadableSignal<List<Todo>> get todos => _todos.readable;

  void add(Todo todo) {
    _todos.update((value) => [...value, todo]);
  }

  void remove(String id) {
    _todos.update(
      (value) => value.where((todo) => todo.id != id).toList(),
    );
  }

  void toggle(String id) {
    _todos.update(
      (value) => [
        for (final todo in value)
          if (todo.id != id) todo else todo.copyWith(completed: !todo.completed)
      ],
    );
  }

  void dispose() {
    _todos.dispose();
  }
}
