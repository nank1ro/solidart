import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:solidart_hooks/solidart_hooks.dart';

class UseResourceExample extends HookWidget {
  const UseResourceExample({super.key});

  @override
  Widget build(BuildContext context) {
    final userResource = useResource(() async {
      await Future.delayed(const Duration(seconds: 1));
      return 'Data ${DateTime.now()}';
    });

    return Scaffold(
      appBar: AppBar(title: const Text('useResource')),
      body: Center(
        child: SignalBuilder(
          builder: (context, child) {
            return userResource.state.when(
              ready: (data) => Text('Result: $data'),
              error: (error, stackTrace) => Text('Error: $error'),
              loading: () => const CircularProgressIndicator(),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => userResource.refresh(),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
