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
  late final ReadSignal<List<Todo>> todos;
  late final ReadSignal<List<Todo>> completedTodos;
  late final ReadSignal<List<Todo>> incompleteTodos;

  @override
  void initState() {
    super.initState();

    // retrieve the whole todos list and the filtered ones
    // this can be done here in the initState, or in the build method.
    // You're not going to experience any performance issues writing the
    // lines below in the build method. Used the initState here just
    // to show you that it's possible.
    // NOTE: If you need to `select` a value from a signal, do it always in the `initState`.
    //       The `select` method creates a new signal every time it runs, and you don't want this to happen.
    todos = context.getProvider<TodosController>().todos;
    completedTodos =
        context.getSignal<ReadSignal<List<Todo>>>(SignalId.completedTodos);
    incompleteTodos =
        context.getSignal<ReadSignal<List<Todo>>>(SignalId.incompleteTodos);
  }

  // Given a [filter] return the correct list of todos
  ReadSignal<List<Todo>> mapFilterToTodosList(TodosFilter filter) {
    switch (filter) {
      case TodosFilter.all:
        return todos;
      case TodosFilter.incomplete:
        return incompleteTodos;
      case TodosFilter.completed:
        return completedTodos;
    }
  }

  @override
  Widget build(BuildContext context) {
    // rebuilds this BuildContext every time the `activeFilter` value changes
    final activeFilter =
        context.observe<TodosFilter>(SignalId.activeTodoFilter);

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
