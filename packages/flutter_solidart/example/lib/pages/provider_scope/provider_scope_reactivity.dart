// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

final _firstCounterProvider = Provider((_) => Signal(0));
final _secondCounterProvider = Provider((_) => Signal(0));

class ProviderScopeReactivityPage extends StatefulWidget {
  const ProviderScopeReactivityPage({super.key});

  @override
  State<ProviderScopeReactivityPage> createState() =>
      _ProviderScopeReactivityPageState();
}

class _ProviderScopeReactivityPageState
    extends State<ProviderScopeReactivityPage> {
  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      providers: [
        _firstCounterProvider,
        _secondCounterProvider,
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
                    _firstCounterProvider.update(
                        context, (value) => value += 1);
                  },
                  child: const Text('+1 counter1'),
                ),
                TextButton(
                  onPressed: () {
                    _secondCounterProvider.update(
                        context, (value) => value += 1);
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
  const _Counter1();

  @override
  Widget build(BuildContext context) {
    final counter1 = _firstCounterProvider.observe(context).value;
    print('build counter1');
    return Text('Counter1: $counter1');
  }
}

class _Counter2 extends StatelessWidget {
  const _Counter2();

  @override
  Widget build(BuildContext context) {
    final counter2 = _secondCounterProvider.observe(context).value;
    print('build counter2');
    return Text('Counter2: $counter2');
  }
}
