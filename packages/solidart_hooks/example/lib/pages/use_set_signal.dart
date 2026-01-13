import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:solidart_hooks/solidart_hooks.dart';

class UseSetSignalExample extends HookWidget {
  const UseSetSignalExample({super.key});

  @override
  Widget build(BuildContext context) {
    final uniqueItems = useSetSignal<String>({'Item1', 'Item2'});

    return Scaffold(
      appBar: AppBar(title: const Text('useSetSignal')),
      body: Center(
        child: SignalBuilder(
          builder: (context, child) {
            return Text('Items: ${uniqueItems.value.join(', ')}');
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => uniqueItems.add('Item${uniqueItems.value.length + 1}'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
