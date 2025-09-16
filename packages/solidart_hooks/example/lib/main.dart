import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:solidart/solidart.dart';
import 'package:solidart_hooks/solidart_hooks.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Example(),
    );
  }
}

class Example extends StatefulHookWidget {
  const Example({super.key});

  @override
  State<Example> createState() => _ExampleState();
}

class _ExampleState extends State<Example> {
  final existingSignal = Signal(10);

  @override
  Widget build(BuildContext context) {
    final count = useSignal(0);
    final doubleCount = useComputed(() => count.value * 2);
    final existing = useExistingSignal(existingSignal);
    useSolidartEffect(() {
      debugPrint(
        'Effect count: ${count.value}, doubleCount: ${doubleCount.value}, existing: ${existing.value}',
      );
    });
    return Scaffold(
      body: Center(
        child: Text(
          'Count: ${count.value}\nDouble: ${doubleCount.value}\n'
          'Existing: ${existing.value}',
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          batch(() {
            count.value++;
            existing.value += 1;
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
