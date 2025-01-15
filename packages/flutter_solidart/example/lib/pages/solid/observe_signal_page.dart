import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

final _countProvider = Provider((_) => Signal(0));

class ObserveSignalPage extends StatelessWidget {
  const ObserveSignalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Observe Signal'),
      ),
      body: ProviderScope(
        providers: [
          // provide the count signal to descendants
          _countProvider,
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
    final count = _countProvider.observe(context);

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
              count.updateValue((value) => value += 1);
            },
            child: const Text('Increment'),
          ),
        ],
      ),
    );
  }
}
