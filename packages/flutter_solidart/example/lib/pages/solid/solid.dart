import 'package:example/pages/solid/multiple_signals_page.dart';
import 'package:example/pages/solid/solid_providers.dart';
import 'package:example/pages/solid/solid_reactivity.dart';
import 'package:example/pages/solid/solid_signals.dart';
import 'package:flutter/material.dart';

import 'observe_signal_page.dart';

final _pages = {
  'Solid Providers': () => const SolidProvidersPage(),
  'Solid Signals': () => const SolidSignalsPage(),
  'Observe Signal': () => const ObserveSignalPage(),
  'Multiple Signals': () => const MultipleSignalsPage(),
  'Reactivity': () => const SolidReactivityPage(),
};

class SolidPage extends StatelessWidget {
  const SolidPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solid')),
      body: ListView.builder(
        itemCount: _pages.length,
        itemBuilder: (BuildContext context, int index) {
          final pageEntry = _pages.entries.elementAt(index);

          return ListTile(
            title: Text(pageEntry.key),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => pageEntry.value(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
