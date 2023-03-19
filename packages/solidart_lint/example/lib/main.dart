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
        'double-counter': () => counter.select((value) => value * 2),
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
    final myClass = context.get();
    // expect_lint: invalid_signal_type
    final invalidSignalType = context.get<MyClass>('1');
    // expect_lint: invalid_provider_type
    final invalidProviderType = context.get<Signal>();
    return const SizedBox();
  }
}
