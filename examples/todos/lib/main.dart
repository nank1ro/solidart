import 'package:flutter/material.dart';
import 'package:solidart_example/pages/todos.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Todos Example',
      home: TodosPage(),
    );
  }
}
