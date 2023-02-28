import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:flutter_solidart/src/utils/diagnostic_properties_for_generic.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

// Used in Solid providers tests
abstract class NameProvider {
  const NameProvider(this.name);

  final String name;

  void dispose();
}

class MockNameProvider extends Mock implements NameProvider {
  MockNameProvider(this.name);

  @override
  final String name;
}

@immutable
class NumberProvider {
  const NumberProvider(this.number);

  final int number;
}

void main() {
  testWidgets('Show widget works properly', (tester) async {
    final s = createSignal(true);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Show(
            when: s,
            builder: (context) => const Text('Builder'),
            fallback: (context) => const Text('Fallback'),
          ),
        ),
      ),
    );
    final builderFinder = find.text('Builder');
    final fallbackFinder = find.text('Fallback');

    expect(builderFinder, findsOneWidget);
    expect(fallbackFinder, findsNothing);

    s.value = false;
    await tester.pumpAndSettle();

    expect(builderFinder, findsNothing);
    expect(fallbackFinder, findsOneWidget);
  });

  testWidgets('ResourceBuilder widget works properly in ResourceReady state',
      (tester) async {
    final s = createSignal(0);
    Future<int> fetcher() {
      return Future.delayed(const Duration(milliseconds: 50), () => s.value);
    }

    final r = createResource(fetcher: fetcher, source: s);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ResourceBuilder(
            resource: r,
            builder: (context, resource) {
              return resource.on(
                ready: (data, refreshing) {
                  return Text('Data: $data refreshing: $refreshing');
                },
                error: (err, _) {
                  return const Text('Error');
                },
                loading: () {
                  return const Text('Loading');
                },
              );
            },
          ),
        ),
      ),
    );
    Finder dataFinder(int value, {bool refreshing = false}) =>
        find.text('Data: $value refreshing: $refreshing');
    final errorFinder = find.text('Error');
    final loadingFinder = find.text('Loading');

    await tester.pumpAndSettle();
    expect(dataFinder(0), findsOneWidget);
    expect(errorFinder, findsNothing);
    expect(loadingFinder, findsNothing);

    unawaited(r.refetch());
    await tester.pumpAndSettle(const Duration(milliseconds: 40));
    expect(dataFinder(0, refreshing: true), findsOneWidget);
    expect(errorFinder, findsNothing);
    expect(loadingFinder, findsNothing);

    await tester.pumpAndSettle();
    expect(dataFinder(0), findsOneWidget);
    expect(errorFinder, findsNothing);
    expect(loadingFinder, findsNothing);
  });

  testWidgets('ResourceBuilder widget works properly in ResourceLoading state',
      (tester) async {
    final s = createSignal(0);
    Future<int> fetcher() {
      return Future.delayed(const Duration(milliseconds: 150), () => s.value);
    }

    final r = createResource(fetcher: fetcher, source: s);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ResourceBuilder(
            resource: r,
            builder: (context, resource) {
              return resource.on(
                ready: (data, refreshing) {
                  return Text('Data: $data refreshing: $refreshing');
                },
                error: (err, _) {
                  return const Text('Error');
                },
                loading: () {
                  return const Text('Loading');
                },
              );
            },
          ),
        ),
      ),
    );
    Finder dataFinder(int value, {bool refreshing = false}) =>
        find.text('Data: $value refreshing: $refreshing');
    final errorFinder = find.text('Error');
    final loadingFinder = find.text('Loading');

    await tester.pumpAndSettle();
    expect(dataFinder(0), findsNothing);
    expect(errorFinder, findsNothing);
    expect(loadingFinder, findsOneWidget);

    await tester.pumpAndSettle();
    expect(dataFinder(0), findsOneWidget);
    expect(errorFinder, findsNothing);
    expect(loadingFinder, findsNothing);
  });

  testWidgets('ResourceBuilder widget works properly in ResourceError state',
      (tester) async {
    final s = createSignal(0);
    Future<int> fetcher() {
      return Future.microtask(() => throw Exception());
    }

    final r = createResource(fetcher: fetcher, source: s);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ResourceBuilder(
            resource: r,
            builder: (context, resource) {
              return resource.on(
                ready: (data, refreshing) {
                  return Text('Data: $data refreshing: $refreshing');
                },
                error: (err, _) {
                  return const Text('Error');
                },
                loading: () {
                  return const Text('Loading');
                },
              );
            },
          ),
        ),
      ),
    );
    Finder dataFinder(int value, {bool refreshing = false}) =>
        find.text('Data: $value refreshing: $refreshing');
    final errorFinder = find.text('Error');
    final loadingFinder = find.text('Loading');

    await tester.pumpAndSettle();
    expect(dataFinder(0), findsNothing);
    expect(errorFinder, findsOneWidget);
    expect(loadingFinder, findsNothing);
  });

  testWidgets('SignalBuilder works properly', (tester) async {
    final s = createSignal(0);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SignalBuilder(
            signal: s,
            builder: (context, value, child) {
              return Text('$value');
            },
          ),
        ),
      ),
    );
    Finder dataFinder(int value) => find.text('$value');

    expect(dataFinder(0), findsOneWidget);
    s.value++;
    await tester.pumpAndSettle();
    expect(dataFinder(1), findsOneWidget);
  });

  testWidgets('DualSignalBuilder works properly', (tester) async {
    final s1 = createSignal(0);
    final s2 = createSignal(0);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DualSignalBuilder(
            firstSignal: s1,
            secondSignal: s2,
            builder: (context, value1, value2, child) {
              return Text('$value1 $value2');
            },
          ),
        ),
      ),
    );
    Finder dataFinder(int value1, int value2) => find.text('$value1 $value2');

    expect(dataFinder(0, 0), findsOneWidget);
    s1.value++;
    await tester.pumpAndSettle();
    expect(dataFinder(1, 0), findsOneWidget);
    s2.value++;
    await tester.pumpAndSettle();
    expect(dataFinder(1, 1), findsOneWidget);
  });

  testWidgets('TripleSignalBuilder works properly', (tester) async {
    final s1 = createSignal(0);
    final s2 = createSignal(0);
    final s3 = createSignal(0);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TripleSignalBuilder(
            firstSignal: s1,
            secondSignal: s2,
            thirdSignal: s3,
            builder: (context, value1, value2, value3, child) {
              return Text('$value1 $value2 $value3');
            },
          ),
        ),
      ),
    );
    Finder dataFinder(int value1, int value2, int value3) =>
        find.text('$value1 $value2 $value3');

    expect(dataFinder(0, 0, 0), findsOneWidget);
    s1.value++;
    await tester.pumpAndSettle();
    expect(dataFinder(1, 0, 0), findsOneWidget);
    s2.value++;
    await tester.pumpAndSettle();
    expect(dataFinder(1, 1, 0), findsOneWidget);
    s3.value++;
    await tester.pumpAndSettle();
    expect(dataFinder(1, 1, 1), findsOneWidget);
  });

  testWidgets('Test Solid context.observe', (tester) async {
    final s = createSignal(0);
    final s2 = s.select((value) => value * 2);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Solid(
            signals: {
              'counter': () => s,
              'double-counter': () => s2,
            },
            child: Builder(
              builder: (context) {
                final counter = context.observe<int>('counter');
                final doubleCounter = context.observe<int>('double-counter');
                return Text('$counter $doubleCounter');
              },
            ),
          ),
        ),
      ),
    );
    Finder counterFinder(int value1, int value2) =>
        find.text('$value1 $value2');
    expect(counterFinder(0, 0), findsOneWidget);

    s.value = 1;
    await tester.pumpAndSettle();
    expect(counterFinder(1, 2), findsOneWidget);
  });

  testWidgets('Test Solid context.get with Signal', (tester) async {
    final s = createSignal(0);
    final s2 = s.select((value) => value * 2);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Solid(
            signals: {
              'counter': () => s,
              'double-counter': () => s2,
            },
            child: Builder(
              builder: (context) {
                final counter = context.get<Signal<int>>('counter');
                final doubleCounter =
                    context.get<ReadableSignal<int>>('double-counter');
                return DualSignalBuilder(
                  firstSignal: counter,
                  secondSignal: doubleCounter,
                  builder: (context, value1, value2, _) {
                    return Text('$value1 $value2');
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
    Finder counterFinder(int value1, int value2) =>
        find.text('$value1 $value2');
    expect(counterFinder(0, 0), findsOneWidget);

    s.value = 1;
    await tester.pumpAndSettle();
    expect(counterFinder(1, 2), findsOneWidget);
  });

  testWidgets('Test Solid throws an error for a not found signal',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Solid(
            signals: {
              'counter': () => createSignal<int>(0),
            },
            child: Builder(
              builder: (context) {
                final counter = context.get<Signal<int>>('invalid-counter');
                return SignalBuilder(
                  signal: counter,
                  builder: (context, value, _) {
                    return Text('$value');
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), const TypeMatcher<SolidSignalError>());
  });

  testWidgets('Test Solid.value with observe', (tester) async {
    Future<void> showCounterDialog({required BuildContext context}) {
      return showDialog(
        context: context,
        builder: (dialogContext) {
          return Solid.value(
            context: context,
            signalIds: const ['counter'],
            child: Builder(
              builder: (innerContext) {
                final counter = innerContext.observe<int>('counter');
                return Text('Dialog counter: $counter');
              },
            ),
          );
        },
      );
    }

    final s = createSignal(0);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Solid(
            signals: {
              'counter': () => s,
            },
            child: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showCounterDialog(context: context);
                  },
                  child: const Text('show dialog'),
                );
              },
            ),
          ),
        ),
      ),
    );
    Finder counterFinder(int value) => find.text('Dialog counter: $value');

    final buttonFinder = find.text('show dialog');
    expect(buttonFinder, findsOneWidget);
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();

    expect(counterFinder(0), findsOneWidget);

    s.value = 1;
    await tester.pumpAndSettle();
    expect(counterFinder(1), findsOneWidget);
  });

  testWidgets('Test Solid.value for signals with get', (tester) async {
    Future<void> showCounterDialog({required BuildContext context}) {
      return showDialog(
        context: context,
        builder: (dialogContext) {
          return Solid.value(
            context: context,
            signalIds: const ['counter', 'double-counter'],
            child: Builder(
              builder: (innerContext) {
                final counter = innerContext.get<Signal<int>>('counter');
                final doubleCounter =
                    innerContext.get<ReadableSignal<int>>('double-counter');
                return DualSignalBuilder(
                  firstSignal: counter,
                  secondSignal: doubleCounter,
                  builder: (_, value1, value2, __) {
                    return Text(
                      'Dialog counter: $value1 doubleCounter: $value2',
                    );
                  },
                );
              },
            ),
          );
        },
      );
    }

    final s = createSignal(0);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Solid(
            signals: {
              'counter': () => s,
              'double-counter': () => s.select<int>((value) => value * 2),
            },
            child: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showCounterDialog(context: context);
                  },
                  child: const Text('show dialog'),
                );
              },
            ),
          ),
        ),
      ),
    );
    Finder counterFinder(int value1, int value2) =>
        find.text('Dialog counter: $value1 doubleCounter: $value2');

    final buttonFinder = find.text('show dialog');
    expect(buttonFinder, findsOneWidget);
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();

    expect(counterFinder(0, 0), findsOneWidget);

    s.value = 1;
    await tester.pumpAndSettle();
    expect(counterFinder(1, 2), findsOneWidget);
  });

  testWidgets(
      '''Trying to retrieve a ReadableSignal as a Signal throws an error, and vice versa''',
      (tester) async {
    final s = ReadableSignal(0);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Solid(
            signals: {
              'counter': () => s,
            },
            child: Builder(
              builder: (context) {
                final counter = context.get<Signal<int>>('counter');
                return SignalBuilder(
                  signal: counter,
                  builder: (context, value, _) {
                    return Text('$value');
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isException);

    final s2 = createSignal(0);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Solid(
            signals: {
              'counter': () => s2,
            },
            child: Builder(
              builder: (context) {
                final counter = context.get<ReadableSignal<int>>('counter');
                return SignalBuilder(
                  signal: counter,
                  builder: (context, value, _) {
                    return Text('$value');
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isException);
  });

  test('DiagnosicPropertyForGeneric', () {
    final builder = DiagnosticPropertiesBuilder();
    DiagnosticPropertiesForGeneric<String>(
      value: 'one',
      name: 'string',
      properties: builder,
    );
    expect(builder.properties.last, const TypeMatcher<StringProperty>());

    DiagnosticPropertiesForGeneric<int>(
      value: 1,
      name: 'int',
      properties: builder,
    );
    expect(builder.properties.last, const TypeMatcher<IntProperty>());

    DiagnosticPropertiesForGeneric<double>(
      value: 1.1,
      name: 'double',
      properties: builder,
    );
    expect(builder.properties.last, const TypeMatcher<DoubleProperty>());

    DiagnosticPropertiesForGeneric<HitTestBehavior>(
      value: HitTestBehavior.translucent,
      name: 'enum',
      properties: builder,
    );
    expect(
      builder.properties.last,
      const TypeMatcher<DiagnosticsProperty<HitTestBehavior>>(),
    );

    DiagnosticPropertiesForGeneric<bool>(
      value: true,
      name: 'bool',
      properties: builder,
    );
    expect(
      builder.properties.last,
      const TypeMatcher<DiagnosticsProperty<bool>>(),
    );

    DiagnosticPropertiesForGeneric<Iterable<int>>(
      value: [1],
      name: 'iterable',
      properties: builder,
    );
    expect(
      builder.properties.last,
      const TypeMatcher<DiagnosticsProperty<Iterable<int>>>(),
    );

    DiagnosticPropertiesForGeneric<Color>(
      value: Colors.black,
      name: 'Color',
      properties: builder,
    );
    expect(
      builder.properties.last,
      const TypeMatcher<DiagnosticsProperty<Color>>(),
    );

    DiagnosticPropertiesForGeneric<IconData>(
      value: Icons.mp,
      name: 'IconData',
      properties: builder,
    );
    expect(
      builder.properties.last,
      const TypeMatcher<IconDataProperty>(),
    );
  });

  testWidgets('Test Solid context.get with providers', (tester) async {
    final nameProvider = MockNameProvider('Ale');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Solid(
            providers: [
              SolidProvider<NameProvider>(
                create: () => nameProvider,
                dispose: (provider) => provider.dispose(),
              ),
              SolidProvider<NumberProvider>(
                create: () => const NumberProvider(1),
                lazy: false,
              ),
            ],
            child: Builder(
              builder: (context) {
                final nameProvider = context.get<NameProvider>();
                final numberProvider = context.get<NumberProvider>();
                return Text('${nameProvider.name} ${numberProvider.number}');
              },
            ),
          ),
        ),
      ),
    );
    Finder providerFinder(String value1, int value2) =>
        find.text('$value1 $value2');
    expect(providerFinder('Ale', 1), findsOneWidget);

    // mock NameProvider dispose method
    when(nameProvider.dispose()).thenReturn(null);
    // Push a different widget
    await tester.pumpWidget(Container());
    // check dispose has been called on NameProvider
    verify(nameProvider.dispose()).called(1);
  });

  testWidgets('Test Solid throws an error for a not found provider',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Solid(
            providers: [
              SolidProvider<NumberProvider>(
                create: () => const NumberProvider(1),
              ),
            ],
            child: Builder(
              builder: (context) {
                // NameProvider is not present
                final nameProvider = context.get<NameProvider>();
                return Text(nameProvider.name);
              },
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), const TypeMatcher<SolidProviderError>());
  });

  testWidgets('Test Solid.value for providers', (tester) async {
    Future<void> showNumberDialog({required BuildContext context}) {
      return showDialog(
        context: context,
        builder: (dialogContext) {
          return Solid.value(
            context: context,
            providerTypes: const [NumberProvider],
            child: Builder(
              builder: (innerContext) {
                final numberProvider = innerContext.get<NumberProvider>();
                return Text('${numberProvider.number}');
              },
            ),
          );
        },
      );
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Solid(
            providers: [
              SolidProvider<NumberProvider>(
                create: () => const NumberProvider(1),
              ),
            ],
            child: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showNumberDialog(context: context);
                  },
                  child: const Text('show dialog'),
                );
              },
            ),
          ),
        ),
      ),
    );
    Finder counterFinder(int value) => find.text('$value');

    final buttonFinder = find.text('show dialog');
    expect(buttonFinder, findsOneWidget);
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();

    expect(counterFinder(1), findsOneWidget);
  });

  testWidgets('Test Solid throws an error for a SolidProvider<dynamic>',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Solid(
            providers: [
              SolidProvider(
                create: () => const NumberProvider(1),
              ),
            ],
            child: const SizedBox(),
          ),
        ),
      ),
    );
    expect(
      tester.takeException(),
      const TypeMatcher<SolidProviderDynamicError>(),
    );
  });

  testWidgets(
      'Test Solid throws an error for multiple providers of the same type',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Solid(
            providers: [
              SolidProvider<NumberProvider>(
                create: () => const NumberProvider(1),
              ),
              SolidProvider<NumberProvider>(
                create: () => const NumberProvider(2),
              ),
            ],
            child: const SizedBox(),
          ),
        ),
      ),
    );
    expect(
      tester.takeException(),
      const TypeMatcher<SolidProviderMultipleProviderOfSameTypeError>(),
    );
  });
}
