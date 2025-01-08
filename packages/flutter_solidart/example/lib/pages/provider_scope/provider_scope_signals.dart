import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

final counterProvider = Provider((context) => Signal(0));

final doubleCounterProvider = Provider.withArgument(
  (_, Signal<int> count) => Computed(() => count() * 2),
);

class ProviderScopeSignalsPage extends StatefulWidget {
  const ProviderScopeSignalsPage({super.key});

  @override
  State<ProviderScopeSignalsPage> createState() =>
      _ProviderScopeSignalsPageState();
}

class _ProviderScopeSignalsPageState extends State<ProviderScopeSignalsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solid Signals'),
      ),
      body: ProviderScope(
        providers: [
          // provide the count signal to descendants
          counterProvider,
        ],
        builder: (context) {
          final count = counterProvider.get(context);
          return ProviderScope(
            providers: [
              // provide the doubleCount signal to descendants
              doubleCounterProvider(count),
            ],
            child: const SomeChild(),
          );
        },
      ),
    );
  }
}

class SomeChild extends StatelessWidget {
  const SomeChild({super.key});

  @override
  Widget build(BuildContext context) {
    // retrieve the count signal
    final count = counterProvider.get(context);
    // retrieve the doubleCount signal
    final doubleCount = doubleCounterProvider.get(context);
    print('doubleCount $doubleCount');

    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // render the count value
          SignalBuilder(
            builder: (context, child) {
              print('count.value ${count.value}');
              return Text('count: ${count.value}');
            },
          ),
          const SizedBox(height: 8),
          // render the double count value
          SignalBuilder(
            builder: (context, child) {
              print('doubleCount.value ${doubleCount.value}');
              return Text('doubleCount: ${doubleCount.value}');
            },
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              // update the count signal value
              counterProvider.update(context, (value) => value += 1);
            },
            child: const Text('Increment'),
          ),
        ],
      ),
    );
  }
}
