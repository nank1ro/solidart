import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

class DualSignalBuilderPage extends StatefulWidget {
  const DualSignalBuilderPage({super.key});

  @override
  State<DualSignalBuilderPage> createState() => _DualSignalBuilderPageState();
}

class _DualSignalBuilderPageState extends State<DualSignalBuilderPage> {
  final counter1 = Signal(0, options: SignalOptions(name: 'counter1'));
  final counter2 = Signal(0, options: SignalOptions(name: 'counter2'));

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('DualSignalBuilder'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SignalBuilder(builder: (_, __) {
              return ListTile(
                title: Text(
                  'First counter: ${counter1.value}',
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium!.copyWith(color: Colors.black),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Second counter: ${counter2.value}',
                    textAlign: TextAlign.center,
                    style: textTheme.titleMedium!.copyWith(color: Colors.black),
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () {
                    counter1.value++;
                  },
                  child: const Text('Counter1++'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    counter2.value++;
                  },
                  child: const Text('Counter2++'),
                )
              ],
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: Text(
                'Using a DualSignalBuilder the builder is fired for each change in any signal. '
                'Even when only one signal updates, the whole builder is called again. '
                'Prefer using the DualSignalBuilder over nesting two [SignalBuilder]s in a single build method.\n\n'
                'See also TripleSignalBuilder for reacting to three signals at once.',
                style: textTheme.titleMedium!.copyWith(color: Colors.blueGrey),
              ),
            )
          ],
        ),
      ),
    );
  }
}
