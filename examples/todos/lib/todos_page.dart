import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:todos/controllers/controller.dart';
import 'package:todos/models/todo.dart';
import 'package:todos/widgets/todos_body.dart';

class TodosPage extends StatelessWidget {
  const TodosPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Using SolidProvider here to provide the [TodosController] to descendants.
    return Solid(
      providers: [
        SolidProvider<TodosController>(
          create: (_) => TodosController(initialTodos: Todo.sample),
          dispose: (_, controller) => controller.dispose(),
        ),
      ],
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
