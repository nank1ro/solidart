// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

void main() {
  runApp(MyApp());
}

final myClassId = ProviderId<MyClass>();
final counterId = ProviderId<Signal<int>>();
final doubleCounterId = ProviderId<Computed<int>>();

class MyClass {}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final counter = Signal(1);

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      providers: [
        myClassId.createProvider(init: () => MyClass()),
        counterId.createProvider(init: () => Signal(0)),
        doubleCounterId.createProvider(
          init: () => Computed(() => counter() * 2),
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
    final myClass = myClassId.get(context);
    final counter = counterId.observe(context);

    return ElevatedButton(
      child: const Text('Increment'),
      onPressed: () {
        counterId.update(context, (value) => throw UnimplementedError());
      },
    );
  }
}
