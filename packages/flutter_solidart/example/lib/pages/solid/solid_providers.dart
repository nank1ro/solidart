import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

final _nameId = ProviderId<NameProvider>();
final _firstNumberId = ProviderId<NumberProvider>();
final _secondNumberId = ProviderId<NumberProvider>();

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
          _nameId.createProvider(
            init: () => const NameProvider('Ale'),
            // the dispose method is fired when the [Solid] widget above is removed from the widget tree.
            dispose: (provider) => provider.dispose(),
          ),
          _firstNumberId.createProvider(
            init: () => const NumberProvider(1),
            // Do not create the provider lazily, but immediately
            lazy: false,
          ),
          _secondNumberId.createProvider(
            init: () => const NumberProvider(100),
            // Do not create the provider lazily, but immediately
            lazy: false,
          ),
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
      builder: (_) => ProviderScope.values(
        mainTreeContext: context,
        providerIds: [
          _nameId,
          _firstNumberId,
          _secondNumberId,
        ],
        child: Dialog(
          child: Builder(builder: (innerContext) {
            final nameProvider = _nameId.get(innerContext);
            final numberProvider1 = _firstNumberId.get(innerContext);
            final numberProvider2 = _secondNumberId.get(innerContext);
            return SizedBox.square(
              dimension: 100,
              child: Center(
                child: Text('''
name: ${nameProvider.name}
number1: ${numberProvider1.number}
number2: ${numberProvider2.number}
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
    final nameProvider = _nameId.get(context);
    final numberProvider = _firstNumberId.get(context);
    final numberProvider2 = _secondNumberId.get(context);

    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('name: ${nameProvider.name}'),
          const SizedBox(height: 8),
          Text('number1: ${numberProvider.number}'),
          const SizedBox(height: 8),
          Text('number2: ${numberProvider2.number}'),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => openDialog(context),
            child: const Text('Open dialog'),
          ),
        ],
      ),
    );
  }
}
