import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

class CounterPage extends StatefulWidget {
  const CounterPage({super.key});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  final counter = Signal(0, name: 'counter');
  late final doubleCounter = Computed(
    () => counter.value * 2,
    name: 'doubleCounter',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Counter')),
      body: Center(
        child: SignalBuilder(
          builder: (_, _) {
            return Text(
              'Counter: ${counter.value}\nDouble: ${doubleCounter.value}',
            );
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
              counter.value -= 1;
            },
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            heroTag: "add hero",
            child: const Icon(Icons.add),
            onPressed: () {
              counter.value += 1;
            },
          ),
        ],
      ),
    );
  }
}
