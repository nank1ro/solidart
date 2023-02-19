import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todos/controllers/controller.dart';
import 'package:todos/models/todo.dart';
import 'package:todos/widgets/todos_body.dart';

class TodosPage extends StatefulWidget {
  const TodosPage({super.key});

  @override
  State<TodosPage> createState() => _TodosPageState();
}

class _TodosPageState extends State<TodosPage> {
  final todosController = TodosController(initialTodos: Todo.sample);

  @override
  void dispose() {
    todosController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Using Provider here to provide the [TodosController] to descendants.
    return Provider(
      create: (_) => todosController,
      child: Scaffold(
        appBar: AppBar(title: const Text('Todos')),
        body: const Padding(
          padding: EdgeInsets.all(8.0),
          child: TodosBody(),
        ),
      ),
    );
  }
}
