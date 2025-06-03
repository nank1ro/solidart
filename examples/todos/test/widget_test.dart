// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:disco/disco.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solidart_example/controllers/todos.dart';
import 'package:solidart_example/domain/todo.dart';
import 'package:solidart_example/main.dart';
import 'package:solidart_example/widgets/todo_item.dart';

// Utility function to easily wrap a [child] into a mocked todos controller.
Widget wrapWithMockedTodosController({
  required Widget child,
  required TodosController todosController,
}) {
  return MaterialApp(
    home: ProviderScopeOverride(
      overrides: [
        todosControllerProvider.overrideWithValue(todosController),
      ],
      child: child,
    ),
  );
}

void main() {
  testWidgets('Todos with initial value', (WidgetTester tester) async {
    // create controller with an initial value
    final initialTodos = List.generate(
      3,
      (i) => Todo(id: i.toString(), task: 'mock$i', completed: false),
    );
    // Build our App and trigger a frame.
    await tester.pumpWidget(
      wrapWithMockedTodosController(
        todosController: TodosController(initialTodos: initialTodos),
        child: const MyApp(),
      ),
    );

    // verify that there are 3 todos rendered initially
    expect(tester.widgetList(find.byType(TodoItem)).length, 3);

    // Verify that the todos list contains 'mock0'
    expect(find.text('mock0'), findsOneWidget);

    // Verify that the todos list contains 'mock1'
    expect(find.text('mock1'), findsOneWidget);

    // Verify that the todos list contains 'mock2'
    expect(find.text('mock2'), findsOneWidget);
  });

  testWidgets('Add a todo', (WidgetTester tester) async {
    // Build our App and trigger a frame.
    await tester.pumpWidget(
      wrapWithMockedTodosController(
        todosController: TodosController(),
        child: const MyApp(),
      ),
    );

    // verify that there are 0 todos rendered initially
    expect(tester.widgetList(find.byType(TodoItem)).length, 0);

    // write and add a new todo
    await tester.enterText(find.byType(TextFormField), 'test todo');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    // verify that there is 1 todos now
    expect(tester.widgetList(find.byType(TodoItem)).length, 1);
    // Verify that the todos list contains 'test todo'
    expect(find.text('test todo'), findsOneWidget);
  });

  testWidgets('Remove a todo', (WidgetTester tester) async {
    // create controller with an initial value
    final initialTodos = List.generate(
      3,
      (i) => Todo(id: i.toString(), task: 'mock$i', completed: false),
    );
    // Build our App and trigger a frame.
    await tester.pumpWidget(
      wrapWithMockedTodosController(
        todosController: TodosController(initialTodos: initialTodos),
        child: const MyApp(),
      ),
    );

    // verify that there are 3 todos rendered initially
    expect(tester.widgetList(find.byType(TodoItem)).length, 3);

    final firstTodoItem = find.byType(TodoItem).first;
    // simulate the drag from right to left
    await tester.fling(
      firstTodoItem,
      const Offset(-300, 0),
      1000,
    );
    await tester.pumpAndSettle();

    // verify that there are 2 todos rendered now
    expect(tester.widgetList(find.byType(TodoItem)).length, 2);
    // Verify that the todos list doesn't contain 'mock0'
    expect(find.text('mock0'), findsNothing);
  });

  testWidgets('Toggle a todo', (WidgetTester tester) async {
    // create controller with an initial value
    final initialTodos = List.generate(
      2,
      (i) => Todo(id: '$i', task: 'mock$i', completed: false),
    );
    final todosController = TodosController(initialTodos: initialTodos);
    // Build our App and trigger a frame.
    await tester.pumpWidget(
      wrapWithMockedTodosController(
        todosController: todosController,
        child: const MyApp(),
      ),
    );

    // verify that the completed tabs starts with 0 todos
    expect(find.text('completed (0)'), findsOneWidget);

    // toggle the first todo
    await tester.tap(find.byType(CheckboxListTile).first);
    await tester.pump();

    // verify that the completed tab shows 1 todo now
    expect(find.text('completed (1)'), findsOneWidget);

    // tap in the completed tab
    await tester.tap(find.text('completed (1)'));
    await tester.pump();

    // Verify that the completed todos list contains 'mock0'
    expect(find.text('mock0'), findsOneWidget);
    // Verify that the completed todos list not contains 'mock1'
    expect(find.text('mock1'), findsNothing);
  });
}
