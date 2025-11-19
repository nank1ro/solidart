import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

class LazyCounterPage extends StatefulWidget {
  const LazyCounterPage({super.key});

  @override
  State<LazyCounterPage> createState() => _LazyCounterPageState();
}

class _LazyCounterPageState extends State<LazyCounterPage> {
  final counter = Signal<int>.lazy(name: 'lazyCounter');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lazy Counter')),
      body: Center(
        child: SignalBuilder(
          builder: (_, _) {
            return switch (counter.hasValue) {
              true => Text('Counter: ${counter.value}'),
              false => const Text('Counter: not initialized'),
            };
          },
        ),
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: "subtract hero",
            child: const Icon(Icons.remove),
            onPressed: () {
              counter.hasValue ? counter.value -= 1 : counter.value = 0;
            },
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            heroTag: "add hero",
            child: const Icon(Icons.add),
            onPressed: () {
              counter.hasValue ? counter.value += 1 : counter.value = 0;
            },
          ),
        ],
      ),
    );
  }
}
