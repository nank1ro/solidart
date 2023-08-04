import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:todos/common/constants.dart';
import 'package:todos/controllers/controller.dart';
import 'package:todos/models/todo.dart';

class Toolbar extends StatefulWidget {
  const Toolbar({super.key});

  @override
  State<Toolbar> createState() => _ToolbarState();
}

class _ToolbarState extends State<Toolbar> {
  /// All the derived signals
  late final ReadSignal<int> allTodosCount;
  late final ReadSignal<int> incompleteTodosCount;
  late final ReadSignal<int> completedTodosCount;

  @override
  void initState() {
    super.initState();
    // retrieve the todos from TodosController.
    final todos = context.get<TodosController>().todos;

    // create derived signals based on the list of todos
    allTodosCount = createComputed(() => todos().length);

    // retrieve the list of completed count and select just the length.
    final completedTodos =
        context.get<ReadSignal<List<Todo>>>(SignalId.completedTodos);
    completedTodosCount = createComputed(() => completedTodos().length);
    // retrieve the list of incomplete count and select just the length.
    final incompleteTodos =
        context.get<ReadSignal<List<Todo>>>(SignalId.incompleteTodos);
    incompleteTodosCount = createComputed(() => incompleteTodos().length);
  }

  @override
  void dispose() {
    allTodosCount.dispose();
    super.dispose();
  }

  /// Maps the given [filter] to the correct list of todos
  ReadSignal<int> mapFilterToTodosList(TodosFilter filter) {
    switch (filter) {
      case TodosFilter.all:
        return allTodosCount;
      case TodosFilter.incomplete:
        return incompleteTodosCount;
      case TodosFilter.completed:
        return completedTodosCount;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: TodosFilter.values.length,
      initialIndex: 0,
      child: TabBar(
        labelColor: Colors.black,
        tabs: TodosFilter.values.map(
          (filter) {
            final todosCount = mapFilterToTodosList(filter);
            // Each tab bar is using its specific todos count signal
            return SignalBuilder(
              signal: todosCount,
              builder: (context, todosCount, _) {
                return Tab(text: '${filter.name} ($todosCount)');
              },
            );
          },
        ).toList(),
        onTap: (index) {
          // update the current active filter
          context.update<TodosFilter>((_) => TodosFilter.values[index]);
        },
      ),
    );
  }
}
