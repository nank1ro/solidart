import 'package:disco/disco.dart';
import 'package:flutter/material.dart';
import 'package:solidart_example/controllers/todos.dart';
import 'package:solidart_example/widgets/todos_body.dart';

class TodosPage extends StatelessWidget {
  const TodosPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Using ProviderScope here to provide the [TodosController] to descendants.
    return ProviderScope(
      providers: [todosControllerProvider],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Todos'),
        ),
        body: const Padding(
          padding: EdgeInsets.all(8),
          child: TodosBody(),
        ),
      ),
    );
  }
}
