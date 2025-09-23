import 'package:flutter/material.dart';
import 'package:solidart_hooks/solidart_hooks.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

final existing = useSignal(0);

class HomeScreen extends SolidartWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final count = useSignal(0);
    final doubleCount = useComputed(() => count.value * 2);

    useEffect(() {
      debugPrint(
        'Effect count: ${count.value}, doubleCount: ${doubleCount.value}, existing: ${existing.value}',
      );
    });

    void increment() {
      count.value++;
      existing.value++;
    }

    return Scaffold(
      body: Center(
        child: Text(
          'Count: ${count.value}\nDouble: ${doubleCount.value}\n'
          'Existing: ${existing.value}',
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: increment,
        child: const Icon(Icons.plus_one),
      ),
    );
  }
}
