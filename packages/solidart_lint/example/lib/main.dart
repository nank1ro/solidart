// ignore_for_file: unused_local_variable

import 'package:disco/disco.dart';
import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

void main() {
  runApp(MyApp());
}

final myClassProvider = Provider((_) => MyClass());
final counterProvider = Provider((_) => Signal(0));
final doubleCounterProvider = Provider.withArgument(
  (_, Signal<int> counter) => Computed(() => counter() * 2),
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
        doubleCounterProvider(counter),
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
    final myClass = myClassProvider.of(context);
    final counter = counterProvider.of(context);

    return ElevatedButton(
      child: const Text('Increment'),
      onPressed: () {
        counter.updateValue((value) => throw UnimplementedError());
      },
    );
  }
}
