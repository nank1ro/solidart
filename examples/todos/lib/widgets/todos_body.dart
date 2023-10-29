import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:todos/controllers/controller.dart';
import 'package:todos/models/todo.dart';
import 'package:todos/widgets/todos_list.dart';
import 'package:todos/widgets/toolbar.dart';

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
    // retrieve the [TodosController], you're safe to `get` a Signal or Provider
    // in both the `initState` and `build` methods.
    final todosController = context.get<TodosController>();

    return Solid(
      providers: [
        // make the active filter signal visible only to descendants.
        // created here because this is where it starts to be necessary.
        Provider<Signal<TodosFilter>>(create: () => Signal(TodosFilter.all)),
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
              onTodoToggle: (id) {
                todosController.toggle(id);
              },
            ),
          ),
        ],
      ),
    );
  }
}
