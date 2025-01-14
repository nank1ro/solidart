import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

final countProvider = Provider((context) => Signal(0));

class ObserveSignalPage extends StatelessWidget {
  const ObserveSignalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Observe Signal'),
      ),
      // provide the count provider to descendants
      body: ProviderScope(
        providers: [countProvider],
        child: const SomeChild(),
      ),
    );
  }
}

class SomeChild extends StatelessWidget {
  const SomeChild({super.key});

  @override
  Widget build(BuildContext context) {
    // react to the count signal

    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // render the count value
          SignalBuilder(
            builder: (context, child) {
              final count = countProvider.get(context);
              return Text('count: ${count.value}');
            },
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              // update the count signal value
              countProvider.update(context, (value) => value + 1);
            },
            child: const Text('Increment'),
          ),
        ],
      ),
    );
  }
}
