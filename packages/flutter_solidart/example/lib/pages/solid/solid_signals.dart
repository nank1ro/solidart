import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

final _counterProvider = Provider.withArg(
  (Signal<int> count) => count,
);

final _doubleCounterProvider = Provider.withArg(
  (Signal<int> count) => Computed(() => count() * 2),
);

class SolidSignalsPage extends StatefulWidget {
  const SolidSignalsPage({super.key});

  @override
  State<SolidSignalsPage> createState() => _SolidSignalsPageState();
}

class _SolidSignalsPageState extends State<SolidSignalsPage> {
  final count = Signal(0);

  @override
  void dispose() {
    count.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solid Signals'),
      ),
      body: ProviderScope(
        providers: [
          // provide the count signal to descendants
          _counterProvider..setInitialArg(count),

          // provide the doubleCount signal to descendants
          _doubleCounterProvider..setInitialArg(count),
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
    final count = _counterProvider.get(context);
    // retrieve the doubleCount signal
    final doubleCount = _doubleCounterProvider.get(context);

    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // render the count value
          SignalBuilder(
            builder: (context, child) {
              return Text('count: ${count.value}');
            },
          ),
          const SizedBox(height: 8),
          // render the double count value
          SignalBuilder(
            builder: (context, child) {
              return Text('doubleCount: ${doubleCount.value}');
            },
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              // update the count signal value
              _counterProvider.update(context, (value) => value += 1);
            },
            child: const Text('Increment'),
          ),
        ],
      ),
    );
  }
}
