import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:material_ui/material_ui.dart';
import 'package:solidart_example/pages/todos.dart';

void main() {
  SolidartConfig.devToolsEnabled = true;
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
