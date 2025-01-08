import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

final _nameProvider = Provider(
  (_) => const NameContainer('Ale'),
  // the dispose method is fired when the [Solid] widget above is removed from the widget tree.
  dispose: (provider) => provider.dispose(),
);
final _firstNumberProvider = Provider(
  (_) => const NumberContainer(1),
  // Do not create the provider lazily, but immediately
  lazy: false,
);
final _secondNumberProvider = Provider(
  (_) => const NumberContainer(100),
  // Do not create the provider lazily, but immediately
  lazy: false,
);

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
          _nameProvider,
          _firstNumberProvider,
          _secondNumberProvider,
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
        providers: [
          _nameProvider,
          _firstNumberProvider,
          _secondNumberProvider,
        ],
        child: Dialog(
          child: Builder(builder: (innerContext) {
            final nameContainer = _nameProvider.get(innerContext);
            final numberContainer1 = _firstNumberProvider.get(innerContext);
            final numberContainer2 = _secondNumberProvider.get(innerContext);
            return SizedBox.square(
              dimension: 100,
              child: Center(
                child: Text('''
name: ${nameContainer.name}
number1: ${numberContainer1.number}
number2: ${numberContainer2.number}
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
    final nameContainer = _nameProvider.get(context);
    final numberContainer1 = _firstNumberProvider.get(context);
    final numberContainer2 = _secondNumberProvider.get(context);

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
          ElevatedButton(
            onPressed: () => openDialog(context),
            child: const Text('Open dialog'),
          ),
        ],
      ),
    );
  }
}
