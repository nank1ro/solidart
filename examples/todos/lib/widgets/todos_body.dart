import 'package:disco/disco.dart';
import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart' hide Provider;
import 'package:solidart_example/controllers/todos.dart';
import 'package:solidart_example/domain/todo.dart';
import 'package:solidart_example/widgets/todos_list.dart';
import 'package:solidart_example/widgets/toolbar.dart';

final todosFilterProvider = Provider((context) => Signal(TodosFilter.all));

class TodosBody extends StatefulWidget {
  const TodosBody({super.key});

  @override
  State<TodosBody> createState() => _TodosBodyState();
}

class _TodosBodyState extends State<TodosBody> {
  final textController = TextEditingController();

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // retrieve the [TodosController], you're safe to retrieve Provider in both
    // the `initState` and `build` methods.
    final todosController = todosControllerProvider.of(context);

    return ProviderScope(
      providers: [
        // make the active filter signal visible only to descendants.
        // scoped here because this is where it starts to be necessary.
        todosFilterProvider,
      ],
      child: Column(
        children: [
          TextFormField(
            controller: textController,
            decoration: const InputDecoration(
              hintText: 'Write new todo',
            ),
            validator: (v) {
              if (v == null || v.isEmpty) {
                return 'Cannot be empty';
              }
              return null;
            },
            onFieldSubmitted: (task) {
              if (task.isEmpty) return;
              final newTodo = Todo.create(task);
              todosController.add(newTodo);
              textController.clear();
            },
          ),
          const SizedBox(height: 16),
          const Toolbar(),
          const SizedBox(height: 16),
          Expanded(
            child: TodoList(
              onTodoToggle: todosController.toggle,
            ),
          ),
        ],
      ),
    );
  }
}
