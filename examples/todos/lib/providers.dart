import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:todos/models/todo.dart';

final todosFilterProvider = Provider<Signal<TodosFilter>>(() => Signal(TodosFilter.all));
