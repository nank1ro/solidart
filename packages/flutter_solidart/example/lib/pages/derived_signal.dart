import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

class DerivedSignalsPage extends StatefulWidget {
  const DerivedSignalsPage({super.key});

  @override
  State<DerivedSignalsPage> createState() => _DerivedSignalsPageState();
}

class _DerivedSignalsPageState extends State<DerivedSignalsPage> {
  late final count = createSignal(0);
  late final doubleCount = count.select((value) => value * 2);

  @override
  void dispose() {
    count.dispose();
    // No need to dispose a SignalSelector because it disposes automatically when the parent disposes
    // doubleCount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Derived Signals'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SignalBuilder(
                signal: count,
                builder: (_, value, __) {
                  return Text('Count: $value');
                }),
            const SizedBox(height: 16),
            SignalBuilder(
                signal: doubleCount,
                builder: (_, value, __) {
                  return Text('Double Count: $value');
                }),
            const SizedBox(height: 16),
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
