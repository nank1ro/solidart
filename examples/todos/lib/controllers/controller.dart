import 'package:solidart/solidart.dart';
import 'package:todos/models/todo.dart';

class TodosController {
  TodosController({
    List<Todo> initialTodos = const [],
  }) : todos = createSignal(initialTodos);

  // Keep the editable todos signal private
  // only the TodoController can mutate the value.
  final Signal<List<Todo>> todos;

  void add(Todo todo) {
    todos.update((value) => [...value, todo]);
  }

  void remove(String id) {
    todos.update(
      (value) => value.where((todo) => todo.id != id).toList(),
    );
  }

  void toogle(String id) {
    todos.update(
      (value) => [
        for (final todo in value)
          if (todo.id != id) todo else todo.copyWith(completed: !todo.completed)
      ],
    );
  }

  void dispose() {
    todos.dispose();
  }
}
