import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

enum _SignalId {
  counter,
  doubleCounter,
}

class SignalsInModalsPage extends StatefulWidget {
  const SignalsInModalsPage({super.key});

  @override
  State<SignalsInModalsPage> createState() => _SignalsInModalsPageState();
}

class _SignalsInModalsPageState extends State<SignalsInModalsPage> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Access Signals in Modals'),
      ),
      body: Solid(
        signals: {
          _SignalId.counter: () => counter,
          _SignalId.doubleCounter: () =>
              counter.select<int>((value) => value * 2),
        },
        child: Builder(
          builder: (context) {
            final counter = context.observe<int>(_SignalId.counter);
            final doubleCounter = context.observe<int>(_SignalId.doubleCounter);

            return Align(
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('counter: $counter'),
                  Text('doubleCounter: $doubleCounter'),
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

  Future<void> showCounterDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (dialogContext) {
        // using `Solid.value` we provide the existing signal(s) to the dialog
        return Solid.value(
          // the context passed must have access to the Solid signals
          context: context,
          // the signals ids that we want to provide to the modal
          signalIds: const [_SignalId.counter, _SignalId.doubleCounter],
          child: Builder(
            builder: (innerContext) {
              final counter = innerContext.observe<int>(_SignalId.counter);
              final doubleCounter =
                  innerContext.observe<int>(_SignalId.doubleCounter);
              return Dialog(
                child: SizedBox(
                  width: 200,
                  height: 100,
                  child: Center(
                    child: ListTile(
                      title: Text("The counter is $counter"),
                      subtitle: Text('The doubleCounter is $doubleCounter'),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
