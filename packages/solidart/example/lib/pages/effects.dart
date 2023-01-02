import 'package:flutter/material.dart';
import 'package:solidart/solidart.dart';

class EffectsPage extends StatefulWidget {
  const EffectsPage({super.key});

  @override
  State<EffectsPage> createState() => _EffectsPageState();
}

class _EffectsPageState extends State<EffectsPage> {
  late final count = createSignal(0);

  @override
  void initState() {
    super.initState();
    createEffect(
      () {
        // ignore: avoid_print
        print("The count is now ${count.value}");
      },
      signals: [count],
    );
  }

  @override
  void dispose() {
    count.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Effects')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Check the console to see the effect printing'),
            const SizedBox(height: 16),
            SignalBuilder(
                signal: count,
                builder: (context, value, __) {
                  return Text('Count: $value');
                }),
          ],
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
