import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solidart/solidart.dart';
import 'package:todos/common/constants.dart';
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
  late final TodosController todosController;
  final textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // retrieve the [TodosController]
    todosController = context.read<TodosController>();
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Solid(
      signals: {
        Signals.completedTodos: () => todosController.todos.select<List<Todo>>(
            (value) => value.where((element) => element.completed).toList()),
        Signals.uncompletedTodos: () => todosController.todos
            .select<List<Todo>>((value) =>
                value.where((element) => !element.completed).toList()),
      },
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
          const Text('Todos'),
          Expanded(
            child: TodoList(
              onTodoToggle: (id) {
                todosController.toogle(id);
              },
            ),
          ),
        ],
      ),
    );
  }
}
