import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:solidart_hooks/solidart_hooks.dart';

class UseSolidartEffectExample extends HookWidget {
  const UseSolidartEffectExample({super.key});

  @override
  Widget build(BuildContext context) {
    final count = useSignal(0);

    useSolidartEffect(() {
      debugPrint('Effect triggered! Count: ${count.value}');
    });

    return Scaffold(
      appBar: AppBar(title: const Text('useSolidartEffect')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Text('Count: ${count.value}')],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => count.value++,
        child: const Icon(Icons.add),
      ),
    );
  }
}
