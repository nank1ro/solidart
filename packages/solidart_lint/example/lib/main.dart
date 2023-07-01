// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

void main() {
  runApp(MyApp());
}

class MyClass {}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final counter = createSignal(1);

  @override
  Widget build(BuildContext context) {
    return Solid(
      providers: [
        // expect_lint: avoid_dynamic_solid_provider
        SolidProvider(create: () => MyClass()),
      ],
      signals: {
        // expect_lint: avoid_dynamic_solid_signal
        'counter': () => createSignal(0),
        // expect_lint: avoid_dynamic_solid_signal
        'double-counter': () => createComputed(() => counter() * 2),
      },
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
    final myClass = context.getProvider();
    // expect_lint: invalid_provider_type
    final invalidProviderType = context.getProvider<Signal>();
    // expect_lint: invalid_observe_type
    final counter = context.observe<Signal<int>>('counter');

    return ElevatedButton(
      child: const Text('Increment'),
      onPressed: () {
        // expect_lint: invalid_update_type
        context.update<Signal<int>>(
            'counter', (value) => throw UnimplementedError());
      },
    );
  }
}
