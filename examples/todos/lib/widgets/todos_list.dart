import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
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
  late final ReadableSignal<List<Todo>> todos;
  late final ReadableSignal<List<Todo>> completedTodos;
  late final ReadableSignal<List<Todo>> uncompletedTodos;

  @override
  void initState() {
    super.initState();

    // retrieve the todos list and the filtered ones
    todos = context.getProvider<TodosController>().todos;
    completedTodos =
        context.get<ReadableSignal<List<Todo>>>(SignalId.completedTodos);
    uncompletedTodos =
        context.get<ReadableSignal<List<Todo>>>(SignalId.uncompletedTodos);
  }

  ReadableSignal<List<Todo>> mapFilterToTodos(TodosFilter filter) {
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
    final activeFilter =
        context.observe<TodosFilter>(SignalId.activeTodoFilter);
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
      },
    );
  }
}
