import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:solidart_hooks/solidart_hooks.dart';

class UseComputedExample extends HookWidget {
  const UseComputedExample({super.key});

  @override
  Widget build(BuildContext context) {
    final count = useSignal(5);
    final doubled = useComputed(() => count.value * 2);

    return Scaffold(
      appBar: AppBar(title: const Text('useComputed')),
      body: Center(
        child: SignalBuilder(
          builder: (context, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Count: ${count.value}'),
                Text('Doubled: ${doubled.value}'),
              ],
            );
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
