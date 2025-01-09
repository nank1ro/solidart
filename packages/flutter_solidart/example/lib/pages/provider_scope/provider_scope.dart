import 'package:example/pages/provider_scope/multiple_signals_page.dart';
import 'package:example/pages/provider_scope/provider_scope_providers.dart';
import 'package:example/pages/provider_scope/provider_scope_reactivity.dart';
import 'package:example/pages/provider_scope/provider_scope_signals.dart';
import 'package:example/pages/provider_scope/same_type.dart';
import 'package:flutter/material.dart';

import 'observe_signal_page.dart';

final _pages = {
  'Solid Providers': () => const ProvidersPage(),
  'Solid Signals': () => const ProviderScopeSignalsPage(),
  'Observe Signal': () => const ObserveSignalPage(),
  'Multiple Signals': () => const MultipleSignalsPage(),
  'Reactivity': () => const ProviderScopeReactivityPage(),
  'SameType': () => const SameTypePage(),
};

class ProviderScopePage extends StatelessWidget {
  const ProviderScopePage({super.key});

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
