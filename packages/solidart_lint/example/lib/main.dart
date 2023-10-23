// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

void main() {
  runApp(MyApp());
}

class MyClass {}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final counter = Signal(1);

  @override
  Widget build(BuildContext context) {
    return Solid(
      providers: [
        // expect_lint: avoid_dynamic_solid_provider
        SolidProvider(create: () => MyClass()),
        // expect_lint: avoid_dynamic_solid_signal
        SolidSignal(create: () => Signal(0), id: 'counter'),
        // expect_lint: avoid_dynamic_solid_signal
        SolidSignal(
          create: () => Computed(() => counter() * 2),
          id: 'double-counter',
        ),
      ],
      child: const MaterialApp(
        title: 'Flutter Demo',
        home: MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // expect_lint: missing_solid_get_type
    final myClass = context.get();
    // expect_lint: invalid_observe_type
    final counter = context.observe<Signal<int>>('counter');

    return ElevatedButton(
      child: const Text('Increment'),
      onPressed: () {
        // expect_lint: invalid_update_type
        context.update<Signal<int>>(
            (value) => throw UnimplementedError(), 'counter');
      },
    );
  }
}
