import 'package:flutter/material.dart';
import 'package:todos/todos_page.dart';

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
