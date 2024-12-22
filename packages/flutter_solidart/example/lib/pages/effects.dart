import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

class EffectsPage extends StatefulWidget {
  const EffectsPage({super.key});

  @override
  State<EffectsPage> createState() => _EffectsPageState();
}

class _EffectsPageState extends State<EffectsPage> {
  final count = Signal(0, name: 'count');
  late final Effect effect;

  @override
  void initState() {
    super.initState();
    effect = Effect(
      (_) {
        // ignore: avoid_print
        print("The count is now ${count.value}");
      },
    );
  }

  @override
  void dispose() {
    effect();
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
            SignalBuilder(builder: (context, child) {
              return Text('Count: ${count.value}');
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
