import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

class ComputedPage extends StatefulWidget {
  const ComputedPage({super.key});

  @override
  State<ComputedPage> createState() => _ComputedPageState();
}

class _ComputedPageState extends State<ComputedPage> {
  late final count = Signal(0, name: 'count');
  late final doubleCount = Computed(() => count.value * 2, name: 'doubleCount');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Computed')),
      body: Center(
        child: SignalBuilder(
          builder: (_, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Count: ${count.value}'),
              const SizedBox(height: 16),
              Text('Double Count: ${doubleCount.value}'),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          count.value++;
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
