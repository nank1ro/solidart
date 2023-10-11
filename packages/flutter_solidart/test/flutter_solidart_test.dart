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
            when: s.call,
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
            builder: (context, resourceState) {
              return resourceState.on(
                ready: (data) {
                  return Text(
                    'Data: $data (refreshing: ${resourceState.isRefreshing})',
                  );
                },
                error: (err, _) {
                  return Text(
                    'Error (refreshing: ${resourceState.isRefreshing})',
                  );
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
        find.text('Data: $value (refreshing: $refreshing)');
    Finder errorFinder({bool refreshing = false}) =>
        find.text('Error (refreshing: $refreshing)');
    final loadingFinder = find.text('Loading');

    await tester.pumpAndSettle();
    expect(dataFinder(0), findsOneWidget);
    expect(errorFinder(), findsNothing);
    expect(loadingFinder, findsNothing);

    unawaited(r.refresh());
    await tester.pumpAndSettle(const Duration(milliseconds: 40));
    expect(dataFinder(0, refreshing: true), findsOneWidget);
    expect(errorFinder(refreshing: true), findsNothing);
    expect(loadingFinder, findsNothing);

    await tester.pumpAndSettle();
    expect(dataFinder(0), findsOneWidget);
    expect(errorFinder(), findsNothing);
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
            builder: (context, resourceState) {
              return resourceState.on(
                ready: (data) {
                  return Text(
                    'Data: $data (refreshing: ${resourceState.isRefreshing})',
                  );
                },
                error: (err, _) {
                  return Text(
                    'Error (refreshing: ${resourceState.isRefreshing})',
                  );
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
        find.text('Data: $value (refreshing: $refreshing)');
    Finder errorFinder({bool refreshing = false}) =>
        find.text('Error (refreshing: $refreshing)');
    final loadingFinder = find.text('Loading');

    await tester.pumpAndSettle();
    expect(dataFinder(0), findsNothing);
    expect(errorFinder(), findsNothing);
    expect(loadingFinder, findsOneWidget);

    await tester.pumpAndSettle();
    expect(dataFinder(0), findsOneWidget);
    expect(errorFinder(), findsNothing);
    expect(loadingFinder, findsNothing);
  });

  testWidgets('ResourceBuilder widget works properly in ResourceError state',
      (tester) async {
    final s = createSignal(0);
    Future<int> fetcher() {
      return Future.delayed(
        const Duration(milliseconds: 150),
        () => throw Exception(),
      );
    }

    final r = createResource(fetcher: fetcher, source: s);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ResourceBuilder(
            resource: r,
            builder: (context, resourceState) {
              return resourceState.on(
                ready: (data) {
                  return Text(
                    'Data: $data (refreshing: ${resourceState.isRefreshing})',
                  );
                },
                error: (err, _) {
                  return Text(
                    'Error (refreshing: ${resourceState.isRefreshing})',
                  );
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
        find.text('Data: $value (refreshing: $refreshing)');
    Finder errorFinder({bool refreshing = false}) =>
        find.text('Error (refreshing: $refreshing)');
    final loadingFinder = find.text('Loading');

    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    expect(dataFinder(0), findsNothing);
    expect(errorFinder(), findsOneWidget);
    expect(loadingFinder, findsNothing);

    unawaited(r.refresh());
    await tester.pumpAndSettle(const Duration(milliseconds: 40));
    expect(dataFinder(0, refreshing: true), findsNothing);
    expect(errorFinder(refreshing: true), findsOneWidget);
    expect(loadingFinder, findsNothing);

    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    expect(dataFinder(0), findsNothing);
    expect(errorFinder(), findsOneWidget);
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

  group('Test Solid context.observe', () {
    testWidgets('Observe signals ids', (tester) async {
      final s = createSignal(0);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Solid(
              providers: [
                SolidSignal<Signal<int>>(create: () => s, id: 'counter'),
                SolidSignal<Computed<int>>(
                  create: () => createComputed(() => s() * 2),
                  id: 'double-counter',
                ),
              ],
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

    testWidgets('Observe Computed', (tester) async {
      final s = createSignal(0);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Solid(
              providers: [
                SolidSignal<Computed<int>>(
                  create: () => createComputed(() => s() * 2),
                ),
              ],
              child: Builder(
                builder: (context) {
                  final doubleCounter = context.observe<int>();
                  return Text('$doubleCounter');
                },
              ),
            ),
          ),
        ),
      );
      Finder counterFinder(int value) => find.text('$value');
      expect(counterFinder(0), findsOneWidget);

      s.value = 1;
      await tester.pumpAndSettle();
      expect(counterFinder(2), findsOneWidget);
    });

    testWidgets('Observe ReadSignal', (tester) async {
      final s = createSignal(0);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Solid(
              providers: [
                SolidSignal<ReadSignal<int>>(create: s.toReadSignal),
              ],
              child: Builder(
                builder: (context) {
                  final counter = context.observe<int>();
                  return Text('$counter');
                },
              ),
            ),
          ),
        ),
      );
      Finder counterFinder(int value) => find.text('$value');
      expect(counterFinder(0), findsOneWidget);

      s.value = 1;
      await tester.pumpAndSettle();
      expect(counterFinder(1), findsOneWidget);
    });
  });

  testWidgets('Test Solid context.get with Signal', (tester) async {
    final s = createSignal(0);
    final s2 = createComputed(() => s() * 2);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Solid(
            providers: [
              SolidSignal<Signal<int>>(create: () => s, id: 'counter'),
              SolidSignal<ReadSignal<int>>(
                create: () => s2,
                id: 'double-counter',
              ),
            ],
            child: Builder(
              builder: (context) {
                final counter = context.get<Signal<int>>('counter');
                final doubleCounter =
                    context.get<ReadSignal<int>>('double-counter');
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
            providers: [
              SolidSignal<Signal<int>>(
                create: () => createSignal(0),
                id: 'counter',
              ),
            ],
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
    expect(
      tester.takeException(),
      const TypeMatcher<SolidProviderError<Signal<int>>>().having(
        (p0) => p0.id,
        'Check error id',
        equals('invalid-counter'),
      ),
    );
  });

  group('Test Solid.value', () {
    testWidgets('Test Solid.value with observe', (tester) async {
      Future<void> showCounterDialog({required BuildContext context}) {
        return showDialog(
          context: context,
          builder: (dialogContext) {
            return Solid.value(
              element: context.getElement<Signal<int>>('counter'),
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
              providers: [
                SolidSignal<Signal<int>>(create: () => s, id: 'counter'),
              ],
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
              elements: [
                context.getElement<Signal<int>>('counter'),
                context.getElement<ReadSignal<int>>('double-counter'),
              ],
              child: Builder(
                builder: (innerContext) {
                  final counter = innerContext.get<Signal<int>>('counter');
                  final doubleCounter =
                      innerContext.get<ReadSignal<int>>('double-counter');
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
              providers: [
                SolidSignal<Signal<int>>(
                  create: () => s,
                  id: 'counter',
                ),
                SolidSignal<Computed<int>>(
                  create: () => createComputed(() => s() * 2),
                  id: 'double-counter',
                ),
              ],
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

    testWidgets('Test Solid.value for providers', (tester) async {
      Future<void> showNumberDialog({required BuildContext context}) {
        return showDialog(
          context: context,
          builder: (dialogContext) {
            return Solid.value(
              element: context.getElement<NumberProvider>(),
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
      );
      Finder counterFinder(int value) => find.text('$value');

      final buttonFinder = find.text('show dialog');
      expect(buttonFinder, findsOneWidget);
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      expect(counterFinder(1), findsOneWidget);
    });

    testWidgets('Test Solid.value throws an error for a not found provider',
        (tester) async {
      Future<void> showNumberDialog({required BuildContext context}) {
        return showDialog(
          context: context,
          builder: (dialogContext) {
            return Solid.value(
              element: context.getElement<NumberProvider>(),
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
                SolidProvider<NameProvider>(
                  create: () => MockNameProvider('name'),
                ),
              ],
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
      );
      final buttonFinder = find.text('show dialog');
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        const TypeMatcher<SolidProviderError<NumberProvider>>(),
      );
    });
  });

  testWidgets('Test Solid.maybeGet returns null for a not found provider',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Solid(
            providers: [
              SolidProvider<NameProvider>(
                create: () => MockNameProvider('name'),
              ),
            ],
            builder: (context) {
              final numberProvider = context.maybeGet<NumberProvider>();
              return Text(numberProvider.toString());
            },
          ),
        ),
      ),
    );
    expect(find.text('null'), findsOneWidget);
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

  testWidgets('Test Solid context.get with SolidProvider', (tester) async {
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
                id: 1,
              ),
              SolidProvider<NumberProvider>(
                create: () => const NumberProvider(100),
                lazy: false,
                id: 2,
              ),
            ],
            child: Builder(
              builder: (context) {
                final nameProvider = context.get<NameProvider>();
                final numberProvider1 = context.get<NumberProvider>(1);
                final numberProvider2 = context.get<NumberProvider>(2);
                return Text(
                  '''${nameProvider.name} ${numberProvider1.number} ${numberProvider2.number}''',
                );
              },
            ),
          ),
        ),
      ),
    );
    Finder providerFinder(String value1, int value2, int value3) =>
        find.text('$value1 $value2 $value3');

    expect(providerFinder('Ale', 1, 100), findsOneWidget);

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
    expect(
      tester.takeException(),
      const TypeMatcher<SolidProviderError<NameProvider>>().having(
        (p0) => p0.id,
        'Check error id null',
        isNull,
      ),
    );
  });

  testWidgets('Test Solid throws an error for a SolidProvider<dynamic>',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Solid(
            providers: [
              SolidProvider(create: () => const NumberProvider(1)),
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

  testWidgets('Test Solid.update method', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Solid(
            providers: [
              SolidSignal<Signal<int>>(create: () => createSignal(0)),
            ],
            child: Builder(
              builder: (context) {
                final counter = context.observe<int>();
                return Column(
                  children: [
                    Text('$counter'),
                    ElevatedButton(
                      onPressed: () {
                        context.update<int>((value) => value + 1);
                      },
                      child: const Text('add'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
    expect(find.text('0'), findsOneWidget);

    expect(find.byType(ElevatedButton), findsOneWidget);
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);
  });

  test(
    'Convert Signal to ValueNotifier',
    () {
      final signal = createSignal(0);
      final notifier = signal.toValueNotifier();
      expect(notifier, isA<ValueNotifier<int>>());

      signal.value = 1;
      expect(notifier.value, 1);
    },
    timeout: const Timeout(Duration(seconds: 1)),
  );

  test(
    'Convert ValueNotifier to Signal',
    () {
      final notifier = ValueNotifier(0);
      final signal = notifier.toSignal();
      expect(signal, isA<Signal<int>>());
      notifier.value = 1;
      expect(signal.value, 1);
    },
    timeout: const Timeout(Duration(seconds: 1)),
  );

  testWidgets('Test Solid multiple ancestor providers of the same Type',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Solid(
            providers: [
              SolidProvider<NumberProvider>(
                create: () => const NumberProvider(1),
                lazy: false,
                id: 1,
              ),
            ],
            child: Solid(
              providers: [
                SolidProvider<NumberProvider>(
                  create: () => const NumberProvider(100),
                  lazy: false,
                  id: 2,
                ),
              ],
              child: Builder(
                builder: (context) {
                  final numberProvider1 = context.get<NumberProvider>(1);
                  final numberProvider2 = context.get<NumberProvider>(2);
                  return Text(
                    '''${numberProvider1.number} ${numberProvider2.number}''',
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    Finder providerFinder(int value1, int value2) =>
        find.text('$value1 $value2');

    expect(providerFinder(1, 100), findsOneWidget);
  });
}
