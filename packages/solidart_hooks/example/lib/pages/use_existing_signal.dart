import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:solidart_hooks/solidart_hooks.dart';

class UseExistingSignalExample extends StatefulHookWidget {
  const UseExistingSignalExample({super.key});

  @override
  State<UseExistingSignalExample> createState() =>
      _UseExistingSignalExampleState();
}

class _UseExistingSignalExampleState extends State<UseExistingSignalExample> {
  final existingSignal = Signal(42);

  @override
  Widget build(BuildContext context) {
    final boundSignal = useExistingSignal(existingSignal);

    return Scaffold(
      appBar: AppBar(title: const Text('useExistingSignal')),
      body: Center(child: Text('Value: ${boundSignal.value}')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => existingSignal.value++,
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    existingSignal.dispose();
    super.dispose();
  }
}
