import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

class SolidSignalsPage extends StatefulWidget {
  const SolidSignalsPage({super.key});

  @override
  State<SolidSignalsPage> createState() => _SolidSignalsPageState();
}

class _SolidSignalsPageState extends State<SolidSignalsPage> {
  final count = createSignal(0);

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
      body: Solid(
        providers: [
          // provide the count signal to descendants
          SolidSignal<Signal<int>>(
            create: () => count,
            // do not autoDispose the signal, because we already dispose it ourself
            autoDispose: false,
          ),

          // provide the doubleCount signal to descendants
          SolidSignal<Computed<int>>(
            create: () => createComputed(() => count() * 2),
          ),
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
    final count = context.get<Signal<int>>();
    // retrieve the doubleCount signal
    final doubleCount = context.get<Computed<int>>();

    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // render the count value
          SignalBuilder(
            signal: count,
            builder: (context, value, child) {
              return Text('count: $value');
            },
          ),
          const SizedBox(height: 8),
          // render the double count value
          SignalBuilder(
            signal: doubleCount,
            builder: (context, value, child) {
              return Text('doubleCount: $value');
            },
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              // update the count signal value
              context.update<int>((value) => value += 1);
            },
            child: const Text('Increment'),
          ),
        ],
      ),
    );
  }
}
