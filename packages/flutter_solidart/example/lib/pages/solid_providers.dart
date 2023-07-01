import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

class NameProvider {
  const NameProvider(this.name);
  final String name;

  void dispose() {
    // put your dispose logic here
    // ignore: avoid_print
    print('dispose name provider');
  }
}

class NumberProvider {
  const NumberProvider(this.number);
  final int number;
}

class SolidProvidersPage extends StatelessWidget {
  const SolidProvidersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solid'),
      ),
      body: Solid(
        providers: [
          SolidProvider<NameProvider>(
            create: () => const NameProvider('Ale'),
            // the dispose method is fired when the [Solid] widget above is removed from the widget tree.
            dispose: (provider) => provider.dispose(),
          ),
          SolidProvider<NumberProvider>(
            create: () => const NumberProvider(1),
            // Do not create the provider lazily, but immediately
            lazy: false,
            id: 1,
          ),
          SolidProvider<NumberProvider>(
            create: () => const NumberProvider(10),
            id: 2,
          ),
        ],
        child: const SomeChildThatNeedsProviders(),
      ),
    );
  }
}

class SomeChildThatNeedsProviders extends StatelessWidget {
  const SomeChildThatNeedsProviders({super.key});

  Future<void> openDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => Solid.value(
        context: context,
        providerTypesOrIds: const [NameProvider, 1, 2],
        child: Dialog(
          child: Builder(builder: (innerContext) {
            final nameProvider = innerContext.getProvider<NameProvider>();
            final numberProvider1 = innerContext.getProvider<NumberProvider>(1);
            final numberProvider2 = innerContext.getProvider<NumberProvider>(2);
            return SizedBox.square(
              dimension: 100,
              child: Center(
                child: Text(
                  'name: ${nameProvider.name}\n'
                  'number1: ${numberProvider1.number}\n'
                  'number2: ${numberProvider2.number}',
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nameProvider = context.getProvider<NameProvider>();
    final numberProvider = context.getProvider<NumberProvider>(1);
    final numberProvider2 = context.getProvider<NumberProvider>(2);
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('name: ${nameProvider.name}'),
          const SizedBox(height: 8),
          Text('number: ${numberProvider.number}'),
          const SizedBox(height: 8),
          Text('number2: ${numberProvider2.number}'),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => openDialog(context),
            child: const Text('Access providers in modals'),
          )
        ],
      ),
    );
  }
}
