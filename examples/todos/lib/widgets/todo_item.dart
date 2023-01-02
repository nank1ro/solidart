import 'package:flutter/material.dart';
import 'package:todos/models/todo.dart';

class TodoItem extends StatelessWidget {
  const TodoItem({
    super.key,
    required this.todo,
    this.onStatusChanged,
  });

  final Todo todo;
  final ValueChanged<bool?>? onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      title: Text(todo.task),
      value: todo.completed,
      onChanged: onStatusChanged,
    );
  }
}
