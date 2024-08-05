import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

class DerivedSignalsPage extends StatefulWidget {
  const DerivedSignalsPage({super.key});

  @override
  State<DerivedSignalsPage> createState() => _DerivedSignalsPageState();
}

class _DerivedSignalsPageState extends State<DerivedSignalsPage> {
  late final count = Signal(0, name: 'count');
  late final doubleCount = Computed(() => count() * 2, name: 'doubleCount');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Derived Signals'),
      ),
      body: Center(
        child: SignalBuilder(
          builder: (_, __) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Count: ${count()}'),
              const SizedBox(height: 16),
              Text('Double Count: ${doubleCount()}'),
              const SizedBox(height: 16),
            ],
          ),
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
