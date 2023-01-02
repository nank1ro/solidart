import 'package:flutter/material.dart';
import 'package:solidart/solidart.dart';

class DualSignalBuilderPage extends StatefulWidget {
  const DualSignalBuilderPage({super.key});

  @override
  State<DualSignalBuilderPage> createState() => _DualSignalBuilderPageState();
}

class _DualSignalBuilderPageState extends State<DualSignalBuilderPage> {
  late final counter1 = createSignal(0);
  late final counter2 = createSignal(0);

  @override
  void dispose() {
    counter1.dispose();
    counter2.dispose();
    super.dispose();
  }

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
            DualSignalBuilder(
                firstSignal: counter1,
                secondSignal: counter2,
                builder: (_, value1, value2, __) {
                  return ListTile(
                    title: Text(
                      'First counter: $value1',
                      textAlign: TextAlign.center,
                      style:
                          textTheme.titleMedium!.copyWith(color: Colors.black),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Second counter: $value2',
                        textAlign: TextAlign.center,
                        style: textTheme.titleMedium!
                            .copyWith(color: Colors.black),
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
                style: textTheme.subtitle1!.copyWith(color: Colors.blueGrey),
              ),
            )
          ],
        ),
      ),
    );
  }
}
