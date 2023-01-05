import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

class AdvancedEffectsPage extends StatefulWidget {
  const AdvancedEffectsPage({super.key});

  @override
  State<AdvancedEffectsPage> createState() => _AdvancedEffectsPageState();
}

class _AdvancedEffectsPageState extends State<AdvancedEffectsPage> {
  final counter = createSignal(0);
  late final Timer timer;
  late final Effect<int> counterEffect;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      counter.value++;
    });
    counterEffect = createEffect(
      () {
        // ignore: avoid_print
        print('The counter is ${counter.value}');
      },
      signals: [counter],
    );
  }

  @override
  void dispose() {
    timer.cancel();
    counter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Effects'),
        actions: [
          TextButton(
            onPressed: () async {
              // pause the effect while in the other page
              // this operation is not performed if the effect is cancelled, you cannot perform any operation
              // on a cancelled effect.
              if (!counterEffect.isCancelled) counterEffect.pause();
              await Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const _SecondPage()));
              // resume the effect when returning in this page
              if (!counterEffect.isCancelled) counterEffect.resume();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: const Text('Go to next page (1)'),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Check the console to see the effect printing'),
            const SizedBox(height: 16),
            SignalBuilder(
              signal: counter,
              builder: (_, value, __) {
                return Text('Counter: $value');
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                counterEffect.cancel();
              },
              child: const Text('Cancel effect (2)'),
            )
          ],
        ),
      ),
    );
  }
}

class _SecondPage extends StatelessWidget {
  // ignore: unused_element
  const _SecondPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Second page'),
      ),
      body: const Center(
        child: Text(
            'You can see that the effect paused when coming in this page.\n\n'
            'The signal is still running, try going back to check the effect output'),
      ),
    );
  }
}
