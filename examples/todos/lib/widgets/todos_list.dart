import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solidart/solidart.dart';
import 'package:todos/common/constants.dart';
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
  late final Signal<List<Todo>> todos;
  late final Signal<List<Todo>> completedTodos;
  late final Signal<List<Todo>> uncompletedTodos;

  @override
  void initState() {
    super.initState();

    // retrieve the todos list
    todos = context.read<TodosController>().todos;
    completedTodos = context.get<List<Todo>>(Signals.completedTodos);
    uncompletedTodos = context.get<List<Todo>>(Signals.uncompletedTodos);
  }

  Signal<List<Todo>> mapFilterToTodos(TodosFilter filter) {
    switch (filter) {
      case TodosFilter.all:
        return todos;
      case TodosFilter.uncompleted:
        return uncompletedTodos;
      case TodosFilter.completed:
        return completedTodos;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeFilter = TodosFilter.all;
    context.listen<TodosFilter>(Signals.activeTodoFilter);
    return SignalBuilder(
        signal: mapFilterToTodos(activeFilter),
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
        });
  }
}
