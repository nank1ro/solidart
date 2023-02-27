import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

class NameProvider {
  const NameProvider(this.name);
  final String name;

  void dispose() {
    // put your dispose logic here
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
            create: (_) => const NameProvider('Ale'),
            // the dispose method is fired when the [Solid] widget above is removed from the widget tree.
            onDispose: (context, provider) => provider.dispose(),
          ),
          SolidProvider<NumberProvider>(
            create: (_) => const NumberProvider(1),
            // Do not create the provider lazily, but immediately
            lazy: false,
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
        providerTypes: const [NameProvider],
        child: Dialog(
          child: Builder(builder: (innerContext) {
            final nameProvider = innerContext.get<NameProvider>();
            return SizedBox.square(
              dimension: 100,
              child: Center(
                child: Text('name: ${nameProvider.name}'),
              ),
            );
          }),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nameProvider = context.get<NameProvider>();
    final numberProvider = context.get<NumberProvider>();
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('name: ${nameProvider.name}'),
          const SizedBox(height: 8),
          Text('number: ${numberProvider.number}'),
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
