import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

class ObserveSignalPage extends StatelessWidget {
  const ObserveSignalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Observe Signal'),
      ),
      body: Solid(
        providers: [
          // provide the count signal to descendants
          Provider<Signal<int>>(create: () => Signal(0)),
        ],
        child: const SomeChild(),
      ),
    );
  }
}

class SomeChild extends StatelessWidget {
  const SomeChild({super.key});

  @override
  Widget build(BuildContext context) {
    // retrieve the count signal
    final count = context.observe<Signal<int>>();

    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // render the count value
          Text('count: ${count.value}'),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              // update the count signal value
              count.value++;
            },
            child: const Text('Increment'),
          ),
        ],
      ),
    );
  }
}
