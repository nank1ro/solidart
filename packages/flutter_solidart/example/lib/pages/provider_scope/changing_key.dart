import 'package:disco/disco.dart';
import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

final counterProvider = Provider.withArgument<Signal<int>, String>(
  (context, arg) {
    print('creating new signal instance with $arg');
    return Signal(0);
  },
  dispose: (s) {
    print('dispose $s');
  },
);

class ChangingKeyPage extends StatefulWidget {
  const ChangingKeyPage({super.key});

  @override
  State<ChangingKeyPage> createState() => _ChangingKeyPageState();
}

class _ChangingKeyPageState extends State<ChangingKeyPage> {
  var providerKey = UniqueKey();

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      key: providerKey,
      providers: [counterProvider(providerKey.toString())],
      child: Builder(builder: (context) {
        return Scaffold(
          body: Center(
            child: SignalBuilder(
              builder: (context, child) {
                final counter = counterProvider.of(context);
                return Text('Counter: ${counter.value}');
              },
            ),
          ),
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                heroTag: 'add',
                onPressed: () {
                  counterProvider.of(context).value++;
                },
                child: const Icon(Icons.add),
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                heroTag: 'clear',
                onPressed: () {
                  setState(() {
                    providerKey = UniqueKey();
                  });
                  print('new key: $providerKey');
                },
                child: const Icon(Icons.clear),
              ),
            ],
          ),
        );
      }),
    );
  }
}
