import 'package:flutter/material.dart';
import 'package:solidart_hooks/solidart_hooks.dart';

class Counter extends SolidartWidget {
  const Counter({super.key});

  @override
  Widget build(BuildContext context) {
    final count = useSignal(0);

    return Scaffold(
      body: Center(child: Text("Count: ${count.value}")),
      floatingActionButton: FloatingActionButton(
        onPressed: () => count.value++,
        child: const Icon(Icons.plus_one),
      ),
    );
  }
}
