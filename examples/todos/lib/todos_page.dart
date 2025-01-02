import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:todos/controllers/controller.dart';
import 'package:todos/models/todo.dart';
import 'package:todos/widgets/todos_body.dart';

class TodosPage extends StatelessWidget {
  const TodosPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Using Provider here to provide the [TodosController] to descendants.
    return ProviderScope(
      providers: [
        TodosController.id.createProvider(
          () => TodosController(initialTodos: Todo.sample),
          dispose: (controller) => controller.dispose(),
        ),
      ],
      child: const TodosPageView(),
    );
  }
}

/// As you can see I'm separating the creation of the Solid widget from the descendants
/// This is necessary for testing, so I can easily mock the `TodosController` and just test the view
class TodosPageView extends StatelessWidget {
  const TodosPageView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todos'),
      ),
      body: const Padding(
        padding: EdgeInsets.all(8.0),
        child: TodosBody(),
      ),
    );
  }
}
