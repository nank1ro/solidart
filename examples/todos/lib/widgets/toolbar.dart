import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solidart/solidart.dart';
import 'package:todos/common/constants.dart';
import 'package:todos/controllers/controller.dart';
import 'package:todos/models/todo.dart';

class Toolbar extends StatefulWidget {
  const Toolbar({super.key});

  @override
  State<Toolbar> createState() => _ToolbarState();
}

class _ToolbarState extends State<Toolbar> {
  late final TodosController todosController;

  /// All the derived signals
  late final Signal<int> allTodosCount;
  late final Signal<int> uncompletedTodosCount;
  late final Signal<int> completedTodosCount;

  @override
  void initState() {
    super.initState();
    // retrieve the TodosController.
    todosController = context.read<TodosController>();
    // get the todos signal
    final todos = todosController.todos;

    // create derived signals based on the list of todos
    // no need to dispose them because they already dispose when the parent (todos) disposes.
    allTodosCount = todos.select((value) => value.length);
    uncompletedTodosCount =
        todos.select((todos) => todos.where((todo) => !todo.completed).length);
    completedTodosCount =
        todos.select((todos) => todos.where((todo) => todo.completed).length);
  }

  // Return the correct signal for the given [filter].
  Signal<int> mapFilterToSignal(TodosFilter filter) {
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
            // Each tab bar is using its specific signal
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
          context.get<TodosFilter>(Signals.activeTodoFilter).value =
              TodosFilter.values[index];
        },
      ),
    );
  }
}
