import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:solidart_hooks/solidart_hooks.dart';

class UseSignalExample extends HookWidget {
  const UseSignalExample({super.key});

  @override
  Widget build(BuildContext context) {
    final count = useSignal(0);

    return Scaffold(
      appBar: AppBar(title: const Text('useSignal')),
      body: Center(
        child: SignalBuilder(
          builder: (context, child) {
            return Text('Count: ${count.value}');
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => count.value++,
        child: const Icon(Icons.add),
      ),
    );
  }
}
