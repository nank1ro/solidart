// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

class SolidReactivityPage extends StatefulWidget {
  const SolidReactivityPage({super.key});

  @override
  State<SolidReactivityPage> createState() => _SolidReactivityPageState();
}

class _SolidReactivityPageState extends State<SolidReactivityPage> {
  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      providers: [
        Provider<Signal<int>>(create: () => Signal(0), id: #firstCounter),
        Provider<Signal<int>>(create: () => Signal(0), id: #secondCounter),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Solid Reactivity'),
        ),
        body: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Check the console to see that the context.observe behaves in a fine-grained way, rebuilding only the specific descendants with the new value. '
                  "It's like using SignalBuilder but works differently under the hood. "
                  'The context.observe should be placed deeper as it causes the whole widget (BuildContext) to rebuild as the value changes.',
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
                    context.update<int>((value) => value += 1, #firstCounter);
                  },
                  child: const Text('+1 counter1'),
                ),
                TextButton(
                  onPressed: () {
                    context.update<int>((value) => value += 1, #secondCounter);
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
    final counter1 = context.observe<Signal<int>>(#firstCounter).value;
    print('build counter1');
    return Text('Counter1: $counter1');
  }
}

class _Counter2 extends StatelessWidget {
  // ignore: unused_element
  const _Counter2({super.key});

  @override
  Widget build(BuildContext context) {
    final counter2 = context.observe<Signal<int>>(#secondCounter).value;
    print('build counter2');
    return Text('Counter2: $counter2');
  }
}
