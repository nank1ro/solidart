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
  late final ReadableSignal<int> allTodosCount;
  late final ReadableSignal<int> uncompletedTodosCount;
  late final ReadableSignal<int> completedTodosCount;

  @override
  void initState() {
    super.initState();
    // retrieve the todos from TodosController.
    final todos = context.getProvider<TodosController>().todos;

    // create derived signals based on the list of todos
    // no need to dispose them because they already dispose when the parent (todos) disposes.
    allTodosCount = todos.select((value) => value.length);

    // retrieve the list of completed count and select the length.
    final completedTodos =
        context.get<ReadableSignal<List<Todo>>>(SignalId.completedTodos);
    completedTodosCount = completedTodos.select((value) => value.length);
    // retrieve the list of uncompleted count and select the length.
    final uncompletedTodos =
        context.get<ReadableSignal<List<Todo>>>(SignalId.uncompletedTodos);
    uncompletedTodosCount = uncompletedTodos.select((value) => value.length);
  }

  // Return the correct signal for the given [filter].
  ReadableSignal<int> mapFilterToSignal(TodosFilter filter) {
    switch (filter) {
      case TodosFilter.all:
        return allTodosCount;
      case TodosFilter.uncompleted:
        return uncompletedTodosCount;
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
            final todosCount = mapFilterToSignal(filter);
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
          // retrieve the activeTodoFilter signal
          // in order to update the current active filter
          final signal =
              context.get<Signal<TodosFilter>>(SignalId.activeTodoFilter);
          signal.value = TodosFilter.values[index];
        },
      ),
    );
  }
}
