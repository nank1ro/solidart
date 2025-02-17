import 'dart:async';

import 'package:disco/disco.dart';
import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

final nameProvider = Provider(
  (context) => const NameContainer('Ale'),
  // the dispose method is fired when the [ProviderScope] widget who provided it is removed from the widget tree.
  dispose: (provider) => provider.dispose(),
);
final firstNumberProvider = Provider(
  (context) => const NumberContainer(1),
  // Do not create the provider lazily, but immediately
  lazy: false,
);
final secondNumberProvider = Provider(
  (context) => const NumberContainer(100),
  // Do not create the provider lazily, but immediately
  lazy: false,
);
final autoIncrementNumberProvider = Provider((context) {
  final count = Signal(0, autoDispose: false);
  final timer = Timer.periodic(
    const Duration(seconds: 1),
    (_) => count.value++,
  );
  count.onDispose(timer.cancel);
  return count;
});

class NameContainer {
  const NameContainer(this.name);
  final String name;

  void dispose() {
    // put your dispose logic here
    // ignore: avoid_print
    print('dispose name provider');
  }
}

class NumberContainer {
  const NumberContainer(this.number);
  final int number;
}

class ProvidersPage extends StatelessWidget {
  const ProvidersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Providers'),
      ),
      body: ProviderScope(
        providers: [
          nameProvider,
          firstNumberProvider,
          secondNumberProvider,
          autoIncrementNumberProvider,
        ],
        child: const SomeChild(),
      ),
    );
  }
}

class SomeChild extends StatelessWidget {
  const SomeChild({super.key});

  Future<void> openDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => ProviderScopePortal(
        mainContext: context,
        child: Dialog(
          child: SignalBuilder(builder: (innerContext, child) {
            final nameContainer = nameProvider.of(innerContext);
            final numberContainer1 = firstNumberProvider.of(innerContext);
            final numberContainer2 = secondNumberProvider.of(innerContext);
            final autoIncrementNumber = autoIncrementNumberProvider.of(context);
            return SizedBox.square(
              dimension: 100,
              child: Center(
                child: Text('''
name: ${nameContainer.name}
number1: ${numberContainer1.number}
number2: ${numberContainer2.number}
autoIncrementNumber: ${autoIncrementNumber.value}
'''),
              ),
            );
          }),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(builder: (context, child) {
      final nameContainer = nameProvider.of(context);
      final numberContainer1 = firstNumberProvider.of(context);
      final numberContainer2 = secondNumberProvider.of(context);
      final autoIncrementNumber = autoIncrementNumberProvider.of(context);
      return Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('name: ${nameContainer.name}'),
            const SizedBox(height: 8),
            Text('number1: ${numberContainer1.number}'),
            const SizedBox(height: 8),
            Text('number2: ${numberContainer2.number}'),
            const SizedBox(height: 8),
            Text('autoIncrementNumber: ${autoIncrementNumber.value}'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => openDialog(context),
              child: const Text('Open dialog'),
            ),
          ],
        ),
      );
    });
  }
}
