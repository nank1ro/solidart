// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

void main() {
  runApp(MyApp());
}

final myClassProvider = Provider(() => MyClass());
final counterProvider = Provider(() => Signal(0));
final doubleCounterProvider = ArgProvider<Signal<int>, Computed<int>>(
  (counter) => Computed(() => counter() * 2),
);

class MyClass {}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final counter = Signal(1);

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      providers: [
        myClassProvider,
        counterProvider,
        doubleCounterProvider..setInitialArg(counter),
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
    final myClass = myClassProvider.get(context);
    final counter = counterProvider.observe(context);

    return ElevatedButton(
      child: const Text('Increment'),
      onPressed: () {
        counterProvider.update(context, (value) => throw UnimplementedError());
      },
    );
  }
}
