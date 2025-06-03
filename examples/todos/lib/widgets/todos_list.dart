import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:solidart_example/controllers/todos.dart';
import 'package:solidart_example/domain/todo.dart';
import 'package:solidart_example/widgets/todo_item.dart';
import 'package:solidart_example/widgets/todos_body.dart';

class TodoList extends StatefulWidget {
  const TodoList({
    super.key,
    this.onTodoToggle,
  });

  final ValueChanged<String>? onTodoToggle;

  @override
  State<TodoList> createState() => _TodoListState();
}

class _TodoListState extends State<TodoList> {
  // retrieve the [TodosController]
  late final todosController = todosControllerProvider.of(context);

  // Given a [filter] return the correct list of todos
  ReadSignal<List<Todo>> mapFilterToTodosList(TodosFilter filter) {
    switch (filter) {
      case TodosFilter.all:
        return todosController.todos;
      case TodosFilter.incomplete:
        return todosController.incompleteTodos;
      case TodosFilter.completed:
        return todosController.completedTodos;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context, child) {
        // rebuilds every time the activeFilter value changes
        final activeFilter = todosFilterProvider.of(context).value;
        // react to the correct list of todos list
        final todos = mapFilterToTodosList(activeFilter).value;
        return ListView.builder(
          itemCount: todos.length,
          itemBuilder: (BuildContext context, int index) {
            final todo = todos[index];
            return TodoItem(
              todo: todo,
              onStatusChanged: (_) {
                widget.onTodoToggle?.call(todo.id);
              },
            );
          },
        );
      },
    );
  }
}
