import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

class SignalsInModals extends StatefulWidget {
  const SignalsInModals({super.key});

  @override
  State<SignalsInModals> createState() => _SignalsInModalsState();
}

class _SignalsInModalsState extends State<SignalsInModals> {
  final counter = createSignal(0);
  late final Timer timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      counter.value++;
    });
  }

  @override
  void dispose() {
    counter.dispose();
    super.dispose();
  }

  Future<void> showCounterDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (dialogContext) {
        // using `Solid.value` we provide the existing signal(s) to the dialog
        return Solid.value(
          // the context passed must have access to the Solid signals
          context: context,
          // the signals ids that we want to provide to the modal
          signalIds: const ['counter'],
          child: Builder(builder: (context) {
            final counter = context.observe<int>('counter');
            return Dialog(
              child: SizedBox(
                width: 200,
                height: 100,
                child: Center(
                  child: Text("The counter is $counter"),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Access Signals in Modals'),
      ),
      body: Solid(
        signals: {
          'counter': () => counter,
        },
        child: Builder(
          builder: (context) {
            final counter = context.observe<int>('counter');
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('counter: $counter'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => showCounterDialog(context),
                    child: const Text('Show dialog'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
