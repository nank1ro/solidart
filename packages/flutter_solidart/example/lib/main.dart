import 'dart:developer' as dev;

import 'package:example/pages/counter.dart';
import 'package:example/pages/computed.dart';
import 'package:example/pages/effects.dart';
import 'package:example/pages/lazy_counter.dart';
import 'package:example/pages/map_signal.dart';
import 'package:example/pages/resource.dart';
import 'package:example/pages/set_signal.dart';
import 'package:example/pages/show.dart';
import 'package:example/pages/signal_builder.dart';
import 'package:example/pages/list_signal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

/// Creating a logger that notifies when signals are created, disposed and updated.
///
class Logger implements SolidartObserver {
  @override
  void didCreateSignal(ReadonlySignal<Object?> signal) {
    final value = _safeValue(signal);
    dev.log('didCreateSignal(name: ${signal.identifier.name}, value: $value)');
  }

  @override
  void didDisposeSignal(ReadonlySignal<Object?> signal) {
    dev.log('didDisposeSignal(name: ${signal.identifier.name})');
  }

  @override
  void didUpdateSignal(ReadonlySignal<Object?> signal) {
    dev.log(
      'didUpdateSignal(name: ${signal.identifier.name}, previousValue: ${signal.previousValue}, value: ${_safeValue(signal)})',
    );
  }
}

Object? _safeValue(ReadonlySignal<Object?> signal) {
  if (signal is LazySignal && !signal.isInitialized) {
    return 'uninitialized';
  }
  try {
    return signal.value;
  } on StateError {
    return 'uninitialized';
  }
}

void main() {
  SolidartConfig.observers.add(Logger());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(useMaterial3: false, primarySwatch: Colors.blue),
      home: const HomePage(),
      routes: routes,
    );
  }
}

// Maps the routes to the specific widget page.
final routes = <String, WidgetBuilder>{
  '/counter': (_) => const CounterPage(),
  '/lazy-counter': (_) => const LazyCounterPage(),
  '/show': (_) => const ShowPage(),
  '/computed': (_) => const ComputedPage(),
  '/effects': (_) => const EffectsPage(),
  '/signal-builder': (_) => const SignalBuilderPage(),
  '/resource': (_) => const ResourcePage(),
  '/list-signal': (_) => const ListSignalPage(),
  '/set-signal': (_) => const SetSignalPage(),
  '/map-signal': (_) => const MapSignalPage(),
};
final routeToNameRegex = RegExp('(?:^/|-)([a-z])');

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final keys = routes.keys;
    return Scaffold(
      appBar: AppBar(title: const Text('Solidart showcase')),
      body: ListView.builder(
        itemCount: routes.length,
        itemBuilder: (BuildContext context, int index) {
          final route = keys.elementAt(index);

          final name = route.replaceAllMapped(
            routeToNameRegex,
            (match) => match.group(0)!.substring(1).toUpperCase(),
          );

          return ListTile(
            title: Text(name),
            onTap: () {
              Navigator.of(context).pushNamed(route);
            },
          );
        },
      ),
    );
  }
}
