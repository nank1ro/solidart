import 'package:solidart/solidart.dart';
import 'package:todos/models/todo.dart';

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

  void toogle(String id) {
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
