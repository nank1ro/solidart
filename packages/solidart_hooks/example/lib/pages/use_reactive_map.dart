import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:solidart_hooks/solidart_hooks.dart';

class UseMapSignalExample extends HookWidget {
  const UseMapSignalExample({super.key});

  @override
  Widget build(BuildContext context) {
    final userRoles = useMapSignal<String, String>({'admin': 'John'});
    return Scaffold(
      appBar: AppBar(title: const Text('useMapSignal')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SignalBuilder(
              builder: (context, child) {
                return Text(
                  'Roles: ${userRoles.value.entries.map((e) => '${e.key}:${e.value}').join(', ')}',
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => userRoles['user${userRoles.value.length}'] =
            'User${userRoles.value.length}',
        child: const Icon(Icons.add),
      ),
    );
  }
}
