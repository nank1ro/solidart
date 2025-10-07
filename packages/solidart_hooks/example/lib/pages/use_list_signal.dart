import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:solidart_hooks/solidart_hooks.dart';

class UseListSignalExample extends HookWidget {
  const UseListSignalExample({super.key});

  @override
  Widget build(BuildContext context) {
    final items = useListSignal<String>(['Item1', 'Item2']);

    return Scaffold(
      appBar: AppBar(title: const Text('useListSignal')),
      body: Center(child: Text('Items: ${items.value.join(', ')}')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => items.add('Item${items.value.length + 1}'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
