import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:todos/controllers/controller.dart';
import 'package:todos/models/todo.dart';
import 'package:todos/widgets/todo_item.dart';

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
  late final todosController = context.get<TodosController>();

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
    // rebuilds this BuildContext every time the `activeFilter` value changes
    final activeFilter = context.observe<TodosFilter>();

    return SignalBuilder(
      // react to the correct list of todos list
      signal: mapFilterToTodosList(activeFilter),
      builder: (_, todos, __) {
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
