import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
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

class Example extends HookWidget {
  const Example({super.key});

  @override
  Widget build(BuildContext context) {
    final count = useSignal(0);
    final doubleCount = useComputed(() => count.value * 2);
    useSolidartEffect(() {
      debugPrint(
        'Effect count: ${count.value}, doubleCount: ${doubleCount.value}',
      );
    });
    return Scaffold(
      body: Center(
        child: Text('Count: ${count.value}\nDouble: ${doubleCount.value}'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => count.value++,
        child: const Icon(Icons.add),
      ),
    );
  }
}
