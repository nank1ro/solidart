import 'package:flutter_test/flutter_test.dart';
import 'package:solidart_example/controllers/todos.dart';
import 'package:solidart_example/domain/todo.dart';

void main() {
  group('TodosController -', () {
    test(' When providing initialTodos, `todos` emits the correct state', () {
      // create controller with an initial value
      const initialTodos = [
        Todo(id: '1', task: 'mock1', completed: false),
        Todo(id: '2', task: 'mock2', completed: false),
      ];
      final controller = TodosController(initialTodos: initialTodos);

      // cleanup resources
      addTearDown(controller.dispose);

      // verify that the list of todos has 2 items
      expect(controller.todos.value, hasLength(2));
    });

    test('Add a todo', () {
      // create controller
      final controller = TodosController();
      // cleanup resources
      addTearDown(controller.dispose);

      // verify that the list of todos is empty
      expect(controller.todos.value, isEmpty);

      // add a todo with id '1'
      controller.add(const Todo(id: '1', task: 'mock1', completed: false));

      // verify that the list of todos increased
      expect(controller.todos.value, hasLength(1));
    });

    test('Remove a todo', () {
      // create controller with an initial value
      const initialTodos = [
        Todo(id: '1', task: 'mock1', completed: false),
        Todo(id: '2', task: 'mock2', completed: false),
      ];
      final controller = TodosController(initialTodos: initialTodos);

      // cleanup resources
      addTearDown(controller.dispose);

      // verify that the list of todos starts with 2 items
      expect(controller.todos.value, hasLength(2));

      // remove the todo with id '1'
      controller.remove('1');

      // verify that the list of todos decreased
      expect(controller.todos.value, hasLength(1));

      // verify that the remained todo has id '2'
      expect(controller.todos.value.first.id, '2');
    });

    test('Toggle a todo', () {
      // create controller with an initial value
      const initialTodos = [
        Todo(id: '1', task: 'mock1', completed: false),
      ];
      final controller = TodosController(initialTodos: initialTodos);

      // cleanup resources
      addTearDown(controller.dispose);

      // verify that the first todo is not completed
      expect(controller.todos.value.first.completed, false);

      // complete the first todo
      controller.toggle('1');

      // verify that the first todo is completed
      expect(controller.todos.value.first.completed, true);
    });
  });
}
