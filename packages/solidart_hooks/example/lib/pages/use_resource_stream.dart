import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:solidart_hooks/solidart_hooks.dart';

class UseResourceStreamExample extends HookWidget {
  const UseResourceStreamExample({super.key});

  @override
  Widget build(BuildContext context) {
    final streamResource = useResourceStream<int>(() {
      return Stream.periodic(const Duration(seconds: 1), (count) => count);
    });

    return Scaffold(
      appBar: AppBar(title: const Text('useResourceStream')),
      body: Center(
        child: SignalBuilder(
          builder: (context, child) {
            return streamResource.state.when(
              ready: (data) => Text('Stream value: $data'),
              error: (error, stackTrace) => Text('Error: $error'),
              loading: () => const CircularProgressIndicator(),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => streamResource.refresh(),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
