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
    final s = Signal(true);
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

  testWidgets('SignalBuilder widget works properly in ResourceReady state',
      (tester) async {
    final s = Signal(0);
    Future<int> fetcher() {
      return Future.delayed(const Duration(milliseconds: 50), () => s.value);
    }

    final r = Resource(fetcher: fetcher, source: s);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SignalBuilder(
            builder: (context, child) {
              final resourceState = r.state;
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

  testWidgets('SignalBuilder widget works properly in ResourceLoading state',
      (tester) async {
    final s = Signal(0);
    Future<int> fetcher() {
      return Future.delayed(const Duration(milliseconds: 150), () => s.value);
    }

    final r = Resource(fetcher: fetcher, source: s);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SignalBuilder(
            builder: (context, child) {
              final resourceState = r.state;
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

  testWidgets('SignalBuilder widget works properly in ResourceError state',
      (tester) async {
    final s = Signal(0);
    Future<int> fetcher() {
      return Future.delayed(
        const Duration(milliseconds: 150),
        () => throw Exception(),
      );
    }

    final r = Resource(fetcher: fetcher, source: s);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SignalBuilder(
            builder: (context, child) {
              final resourceState = r.state;
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
    final s = Signal(0);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SignalBuilder(
            builder: (context, child) {
              return Text(s().toString());
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
    final s1 = Signal(0);
    final s2 = Signal(0);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SignalBuilder(
            builder: (context, child) {
              return Text('${s1()} ${s2()}');
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
    final s1 = Signal(0);
    final s2 = Signal(0);
    final s3 = Signal(0);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SignalBuilder(
            builder: (context, child) {
              return Text('${s1()} ${s2()} ${s3()}');
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
      final s = Signal(0);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Solid(
              providers: [
                Provider<Signal<int>>(create: () => s, id: 'counter'),
                Provider<Computed<int>>(
                  create: () => Computed(() => s() * 2),
                  id: 'double-counter',
                ),
              ],
              builder: (context) {
                final counter = context.observe<Signal<int>>('counter').value;
                final doubleCounter =
                    context.observe<Computed<int>>('double-counter').value;
                return Text('$counter $doubleCounter');
              },
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
      final s = Signal(0);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Solid(
              providers: [
                Provider<Computed<int>>(
                  create: () => Computed(() => s() * 2),
                ),
              ],
              builder: (context) {
                final doubleCounter = context.observe<Computed<int>>().value;
                return Text('$doubleCounter');
              },
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
      final s = Signal(0);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Solid(
              providers: [
                Provider<ReadSignal<int>>(create: s.toReadSignal),
              ],
              builder: (context) {
                final counter = context.observe<ReadSignal<int>>().value;
                return Text('$counter');
              },
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

    testWidgets('Observe ReadSignal with id', (tester) async {
      final s = Signal(0);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Solid(
              providers: [
                Provider<ReadSignal<int>>(
                  create: s.toReadSignal,
                  id: #counter,
                ),
              ],
              builder: (context) {
                final counter =
                    context.observe<ReadSignal<int>>(#counter).value;
                return Text('$counter');
              },
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
    final s = Signal(0);
    final s2 = Computed(() => s() * 2);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Solid(
            providers: [
              Provider<Signal<int>>(create: () => s, id: 'counter'),
              Provider<ReadSignal<int>>(
                create: () => s2,
                id: 'double-counter',
              ),
            ],
            builder: (context) {
              final counter = context.get<Signal<int>>('counter');
              final doubleCounter =
                  context.get<ReadSignal<int>>('double-counter');
              return SignalBuilder(
                builder: (context, _) {
                  return Text('${counter()} ${doubleCounter()}');
                },
              );
            },
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
              Provider<Signal<int>>(
                create: () => Signal(0),
                id: 'counter',
              ),
            ],
            builder: (context) {
              final counter = context.get<Signal<int>>('invalid-counter');
              return SignalBuilder(
                builder: (context, _) {
                  return Text(counter().toString());
                },
              );
            },
          ),
        ),
      ),
    );
    expect(
      tester.takeException(),
      const TypeMatcher<ProviderError<Signal<int>>>().having(
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
                  final counter =
                      innerContext.observe<Signal<int>>('counter').value;
                  return Text('Dialog counter: $counter');
                },
              ),
            );
          },
        );
      }

      final s = Signal(0);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Solid(
              providers: [
                Provider<Signal<int>>(create: () => s, id: 'counter'),
              ],
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
                context.getElement<Computed<int>>('double-counter'),
              ],
              child: Builder(
                builder: (innerContext) {
                  final counter = innerContext.get<Signal<int>>('counter');
                  final doubleCounter =
                      innerContext.get<Computed<int>>('double-counter');
                  return SignalBuilder(
                    builder: (_, __) {
                      return Text(
                        '''Dialog counter: ${counter()} doubleCounter: ${doubleCounter()}''',
                      );
                    },
                  );
                },
              ),
            );
          },
        );
      }

      final s = Signal(0);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Solid(
              providers: [
                Provider<Signal<int>>(
                  create: () => s,
                  id: 'counter',
                ),
                Provider<Computed<int>>(
                  create: () => Computed(() => s() * 2),
                  id: 'double-counter',
                ),
              ],
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
                Provider<NumberProvider>(
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
                Provider<NameProvider>(
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
        const TypeMatcher<ProviderError<NumberProvider>>(),
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
              Provider<NameProvider>(
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

  testWidgets('Test Solid context.get with Provider', (tester) async {
    final nameProvider = MockNameProvider('Ale');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Solid(
            providers: [
              Provider<NameProvider>(
                create: () => nameProvider,
                dispose: (provider) => provider.dispose(),
              ),
              Provider<NumberProvider>(
                create: () => const NumberProvider(1),
                lazy: false,
                id: 1,
              ),
              Provider<NumberProvider>(
                create: () => const NumberProvider(100),
                lazy: false,
                id: 2,
              ),
            ],
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
              Provider<NumberProvider>(
                create: () => const NumberProvider(1),
              ),
            ],
            builder: (context) {
              // NameProvider is not present
              final nameProvider = context.get<NameProvider>();
              return Text(nameProvider.name);
            },
          ),
        ),
      ),
    );
    expect(
      tester.takeException(),
      const TypeMatcher<ProviderError<NameProvider>>().having(
        (p0) => p0.id,
        'Check error id null',
        isNull,
      ),
    );
  });

  testWidgets('Test Solid throws an error for a Provider<dynamic>',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Solid(
            providers: [
              Provider(create: () => const NumberProvider(1)),
            ],
            child: const SizedBox(),
          ),
        ),
      ),
    );
    expect(
      tester.takeException(),
      const TypeMatcher<ProviderDynamicError>(),
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
              Provider<NumberProvider>(
                create: () => const NumberProvider(1),
              ),
              Provider<NumberProvider>(
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
      const TypeMatcher<ProviderMultipleProviderOfSameTypeError>(),
    );
  });

  testWidgets('Test Solid.update method', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Solid(
            providers: [
              Provider<Signal<int>>(create: () => Signal(0)),
            ],
            builder: (context) {
              final counter = context.observe<Signal<int>>().value;
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
      final signal = Signal(0);
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
              Provider<NumberProvider>(
                create: () => const NumberProvider(1),
                lazy: false,
                id: 1,
              ),
            ],
            child: Solid(
              providers: [
                Provider<NumberProvider>(
                  create: () => const NumberProvider(100),
                  lazy: false,
                  id: 2,
                ),
              ],
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
    );
    Finder providerFinder(int value1, int value2) =>
        find.text('$value1 $value2');

    expect(providerFinder(1, 100), findsOneWidget);
  });

  group('Automatic disposal', () {
    testWidgets(
      'Signal autoDispose',
      (tester) async {
        final counter = Signal(0);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SignalBuilder(
                builder: (_, __) {
                  return Text(counter().toString());
                },
              ),
            ),
          ),
        );
        expect(counter.disposed, isFalse);
        await tester.pumpWidget(const SizedBox());
        expect(counter.disposed, isTrue);
      },
      timeout: const Timeout(Duration(seconds: 1)),
    );

    testWidgets(
      'ReadSignal autoDispose',
      (tester) async {
        final counter = Signal(0).toReadSignal();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SignalBuilder(
                builder: (_, __) {
                  return Text(counter().toString());
                },
              ),
            ),
          ),
        );
        expect(counter.disposed, isFalse);
        await tester.pumpWidget(const SizedBox());
        expect(counter.disposed, isTrue);
      },
      timeout: const Timeout(Duration(seconds: 1)),
    );

    testWidgets(
      'Computed autoDispose',
      (tester) async {
        final counter = Signal(0);
        final doubleCounter = Computed(() => counter() * 2);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SignalBuilder(
                builder: (_, __) {
                  return Text(doubleCounter().toString());
                },
              ),
            ),
          ),
        );
        expect(counter.disposed, isFalse);
        expect(doubleCounter.disposed, isFalse);
        await tester.pumpWidget(const SizedBox());
        expect(counter.disposed, isTrue);
        expect(doubleCounter.disposed, isTrue);
      },
      timeout: const Timeout(Duration(seconds: 1)),
    );

    testWidgets(
      'Effect autoDispose',
      (tester) async {
        final counter = Signal(0);
        final effect = Effect((_) => counter());
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SignalBuilder(
                builder: (_, __) {
                  return Text(counter().toString());
                },
              ),
            ),
          ),
        );
        expect(counter.disposed, isFalse);
        expect(effect.disposed, isFalse);
        await tester.pumpWidget(const SizedBox());
        counter.dispose();
        expect(effect.disposed, isTrue);
      },
      timeout: const Timeout(Duration(seconds: 1)),
    );

    testWidgets(
      'Resource autoDispose',
      (tester) async {
        final r = Resource(fetcher: () => Future.value(0));
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SignalBuilder(
                builder: (_, __) {
                  return Text(r.state.toString());
                },
              ),
            ),
          ),
        );
        expect(r.disposed, isFalse);
        await tester.pumpWidget(const SizedBox());
        expect(r.disposed, isTrue);
      },
      timeout: const Timeout(Duration(seconds: 1)),
    );
  });

  testWidgets(
    'Effect with multiple dependencies autoDispose',
    (tester) async {
      final counter = Signal(0);
      final doubleCounter = Computed(() => counter() * 2);
      final effect = Effect((_) {
        counter();
        doubleCounter();
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SignalBuilder(
              builder: (_, __) {
                return Text(counter().toString());
              },
            ),
          ),
        ),
      );
      expect(counter.disposed, isFalse);
      expect(doubleCounter.disposed, isFalse);
      expect(effect.disposed, isFalse);
      await tester.pumpWidget(const SizedBox());
      effect();
      expect(effect.disposed, isTrue);
      expect(counter.disposed, isTrue);
      expect(doubleCounter.disposed, isTrue);
    },
    timeout: const Timeout(Duration(seconds: 1)),
  );

  testWidgets(
      'SolidOverride should override providers regardless of the hierarchy',
      (tester) async {
    await tester.pumpWidget(
      SolidOverride(
        providers: [
          Provider<Signal<int>>(create: () => Signal(100)),
        ],
        child: MaterialApp(
          home: Solid(
            providers: [
              Provider<Signal<int>>(create: () => Signal(0)),
            ],
            builder: (context) {
              final counter = context.observe<Signal<int>>().value;
              return Text(counter.toString());
            },
          ),
        ),
      ),
    );
    expect(find.text('100'), findsOneWidget);
  });

  testWidgets('Only one SolidOverride must be present in the widget tree',
      (tester) async {
    await tester.pumpWidget(
      SolidOverride(
        providers: [
          Provider<Signal<int>>(create: () => Signal(100)),
        ],
        child: MaterialApp(
          home: SolidOverride(
            providers: [
              Provider<Signal<int>>(create: () => Signal(0)),
            ],
            builder: (context) {
              final counter = context.observe<Signal<int>>().value;
              return Text(counter.toString());
            },
          ),
        ),
      ),
    );
    expect(
      tester.takeException(),
      const TypeMatcher<MultipleSolidOverrideError>(),
    );
  });

  testWidgets(
      '''SolidOverride.of(context) throws an error if no SolidOverride is found in the widget tree''',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              SolidOverride.of(context);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    expect(
      tester.takeException(),
      const TypeMatcher<FlutterError>(),
    );
  });
}
