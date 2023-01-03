// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:solidart/solidart.dart';

// Used as signal keys for [Solid]
enum SignalId {
  firstCounter,
  secondCounter,
}

class SolidReactivity extends StatefulWidget {
  const SolidReactivity({super.key});

  @override
  State<SolidReactivity> createState() => _SolidReactivityState();
}

class _SolidReactivityState extends State<SolidReactivity> {
  @override
  Widget build(BuildContext context) {
    return Solid(
      signals: {
        SignalId.firstCounter: () => createSignal<int>(0),
        SignalId.secondCounter: () => createSignal<int>(0),
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Solid Reactivity'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  'Check the console to see that the context.watch behaves in a fine-grained way, rebuilding only the specific descendants with the new value. '
                  "It's like using SignalBuilder but works differently under the hood. "
                  'The context.watch should be placed deeper as it causes the whole widget to rebuild as the value changes.',
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                _Counter1(),
                SizedBox(height: 16),
                _Counter2(),
              ],
            ),
          ),
        ),
        floatingActionButton: Builder(
          // using a builder to get a descendant context for getting [Solid]
          builder: (context) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    context.get<Signal<int>>(SignalId.firstCounter).value++;
                  },
                  child: const Text('+1 counter1'),
                ),
                TextButton(
                  onPressed: () {
                    context.get<Signal<int>>(SignalId.secondCounter).value++;
                  },
                  child: const Text('+1 counter2'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Counter1 extends StatelessWidget {
  // ignore: unused_element
  const _Counter1({super.key});

  @override
  Widget build(BuildContext context) {
    final counter1 = context.observe<int>(SignalId.firstCounter);
    print('build counter1');
    return Text('Counter1: $counter1');
  }
}

class _Counter2 extends StatelessWidget {
  // ignore: unused_element
  const _Counter2({super.key});

  @override
  Widget build(BuildContext context) {
    final counter2 = context.observe<int>(SignalId.secondCounter);
    print('build counter2');
    return Text('Counter2: $counter2');
  }
}
