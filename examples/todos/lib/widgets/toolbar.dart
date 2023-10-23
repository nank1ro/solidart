import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:todos/controllers/controller.dart';
import 'package:todos/models/todo.dart';

class Toolbar extends StatefulWidget {
  const Toolbar({super.key});

  @override
  State<Toolbar> createState() => _ToolbarState();
}

class _ToolbarState extends State<Toolbar> {
  // retrieve the [TodosController]
  late final todosController = context.get<TodosController>();

  /// All the derived signals, they will react only when the `length` property changes
  late final allTodosCount = Computed(() => todosController.todos().length);
  late final incompleteTodosCount =
      Computed(() => todosController.incompleteTodos().length);
  late final completedTodosCount =
      Computed(() => todosController.completedTodos().length);

  @override
  void dispose() {
    allTodosCount.dispose();
    incompleteTodosCount.dispose();
    completedTodosCount.dispose();
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
