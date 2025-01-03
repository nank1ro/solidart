import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:flutter_solidart/src/utils/diagnostic_properties_for_generic.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

// Used in Solid providers tests
abstract class NameContainer {
  const NameContainer(this.name);

  final String name;

  void dispose();
}

class MockNameContainer extends Mock implements NameContainer {
  MockNameContainer(this.name);

  @override
  final String name;
}

@immutable
class NumberContainer {
  const NumberContainer(this.number);

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

    final r = Resource(fetcher, source: s);
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

    final r = Resource(fetcher, source: s);
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

    final r = Resource(fetcher, source: s);
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

  group('Test ProviderScope context.observe', () {
    testWidgets('Observe signals ids', (tester) async {
      final s = Signal(0);

      final counterProvider = Provider((_) => s);
      final doubleCounterProvider = Provider((_) => Computed(() => s() * 2));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProviderScope.builder(
              providers: [
                counterProvider,
                doubleCounterProvider,
              ],
              builder: (context) {
                final counter = counterProvider.observe(context).value;
                final doubleCounter =
                    doubleCounterProvider.observe(context).value;
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

      final doubleCounterProvider = Provider((_) => Computed(() => s() * 2));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProviderScope.builder(
              providers: [
                doubleCounterProvider,
              ],
              builder: (context) {
                final doubleCounter =
                    doubleCounterProvider.observe(context).value;
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

      final counterProvider = Provider((_) => s.toReadSignal());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProviderScope.builder(
              providers: [
                counterProvider,
              ],
              builder: (context) {
                final counter = counterProvider.observe(context).value;
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

      final counterProvider = Provider((_) => s.toReadSignal());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProviderScope.builder(
              providers: [
                counterProvider,
              ],
              builder: (context) {
                final counter = counterProvider.observe(context).value;
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

  testWidgets('Test ProviderScope context.get with Signal', (tester) async {
    final s = Signal(0);
    final s2 = Computed(() => s() * 2);

    final counterProvider = Provider((_) => s);
    final doubleCounterProvider = Provider((_) => s2);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderScope.builder(
            providers: [
              counterProvider,
              doubleCounterProvider,
            ],
            builder: (context) {
              final counter = counterProvider.get(context);
              final doubleCounter = doubleCounterProvider.get(context);
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

  testWidgets('Test ProviderScope throws an error for a not found signal',
      (tester) async {
    final counterProvider = Provider((_) => Signal(0));
    final invalidCounterProvider = Provider((_) => Signal(0));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderScope.builder(
            providers: [
              counterProvider,
            ],
            builder: (context) {
              final counter = invalidCounterProvider.get(context);
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
        (pe) => pe.id,
        'Matching the wrong ID should result in a ProviderError.',
        equals(invalidCounterProvider),
      ),
    );
  });

  group('Test ProviderScope.value', () {
    testWidgets('Test ProviderScope.value with observe', (tester) async {
      final s = Signal(0);
      final counterProvider = Provider((_) => s);

      Future<void> showCounterDialog({required BuildContext context}) {
        return showDialog(
          context: context,
          builder: (dialogContext) {
            return ProviderScope.value(
              mainTreeContext: context,
              provider: counterProvider,
              child: Builder(
                builder: (innerContext) {
                  final counter = counterProvider.observe(innerContext).value;
                  return Text('Dialog counter: $counter');
                },
              ),
            );
          },
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProviderScope.builder(
              providers: [
                counterProvider,
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

    testWidgets('Test ProviderScope.value for signals with get',
        (tester) async {
      final s = Signal(0);
      final counterProvider = Provider((_) => s);
      final doubleCounterProvider = Provider((_) => Computed(() => s() * 2));

      Future<void> showCounterDialog({required BuildContext context}) {
        return showDialog(
          context: context,
          builder: (dialogContext) {
            return ProviderScope.values(
              mainTreeContext: context,
              providers: [
                counterProvider,
                doubleCounterProvider,
              ],
              child: Builder(
                builder: (innerContext) {
                  final counter = counterProvider.get(innerContext);
                  final doubleCounter = doubleCounterProvider.get(innerContext);
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

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProviderScope.builder(
              providers: [
                counterProvider,
                doubleCounterProvider,
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

    testWidgets('Test ProviderScope.value for providers', (tester) async {
      final numberContainerProvider = Provider((_) => const NumberContainer(1));

      Future<void> showNumberDialog({required BuildContext context}) {
        return showDialog(
          context: context,
          builder: (dialogContext) {
            return ProviderScope.value(
              provider: numberContainerProvider,
              mainTreeContext: context,
              child: Builder(
                builder: (innerContext) {
                  final numberContainer =
                      numberContainerProvider.get(innerContext);
                  return Text('${numberContainer.number}');
                },
              ),
            );
          },
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProviderScope.builder(
              providers: [
                numberContainerProvider,
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

    testWidgets(
        'Test ProviderScope.value throws an error for a not found provider',
        (tester) async {
      final numberContainerProvider = Provider((_) => const NumberContainer(0));
      final nameContainerProvider =
          Provider<NameContainer>((_) => MockNameContainer('name'));

      Future<void> showNumberDialog({required BuildContext context}) {
        return showDialog(
          context: context,
          builder: (dialogContext) {
            return ProviderScope.value(
              provider: numberContainerProvider,
              mainTreeContext: context,
              child: Builder(
                builder: (innerContext) {
                  final numberContainer =
                      numberContainerProvider.get(innerContext);
                  return Text('${numberContainer.number}');
                },
              ),
            );
          },
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProviderScope.builder(
              providers: [nameContainerProvider],
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
        const TypeMatcher<ProviderError<NumberContainer>>(),
      );
    });
  });

  testWidgets(
      'Test ProviderScope.maybeGet returns null for a not found provider',
      (tester) async {
    final numberContainerProvider = Provider((_) => const NumberContainer(0));
    final nameContainerProvider = Provider<NameContainer>(
      (_) => MockNameContainer('name'),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderScope.builder(
            providers: [
              nameContainerProvider,
            ],
            builder: (context) {
              final numberContainer = numberContainerProvider.maybeGet(context);
              return Text(numberContainer.toString());
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

  testWidgets('Test ProviderScope context.get with Provider', (tester) async {
    final NameContainer nameContainer = MockNameContainer('Ale');

    final numberContainer1Provider = Provider(
      (_) => const NumberContainer(1),
      lazy: false,
    );
    final numberContainer2Provider = Provider(
      (_) => const NumberContainer(100),
      lazy: false,
    );
    final nameContainerProvider = Provider(
      (_) => nameContainer,
      dispose: (provider) => provider.dispose(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderScope.builder(
            providers: [
              nameContainerProvider,
              numberContainer1Provider,
              numberContainer2Provider,
            ],
            builder: (context) {
              final nameContainer = nameContainerProvider.get(context);
              final numberContainer1 = numberContainer1Provider.get(context);
              final numberContainer2 = numberContainer2Provider.get(context);
              return Text(
                '''${nameContainer.name} ${numberContainer1.number} ${numberContainer2.number}''',
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
    when(nameContainer.dispose()).thenReturn(null);
    // Push a different widget
    await tester.pumpWidget(Container());
    // check dispose has been called on NameProvider
    verify(nameContainer.dispose()).called(1);
  });

  testWidgets('Test ProviderScope throws an error for a not found provider',
      (tester) async {
    final numberContainerProvider = Provider((_) => const NumberContainer(1));
    final nameContainerProvider = Provider((_) => MockNameContainer('An'));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderScope.builder(
            providers: [
              numberContainerProvider,
            ],
            builder: (context) {
              // NameProvider is not present
              final nameContainer = nameContainerProvider.get(context);
              return Text(nameContainer.name);
            },
          ),
        ),
      ),
    );
    expect(
      tester.takeException(),
      const TypeMatcher<ProviderError<NameContainer>>().having(
        (pe) => pe.id,
        'The wrong ID is used.',
        nameContainerProvider,
      ),
    );
  });

  testWidgets('Test ProviderScope throws an error for a Provider<dynamic>',
      (tester) async {
    final numberContainerProvider =
        Provider<dynamic>((_) => const NumberContainer(1));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderScope(
            providers: [
              numberContainerProvider,
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
      'Test ProviderScope throws an error for multiple providers of the same type',
      (tester) async {
    final numberContainerProvider = Provider((_) => const NumberContainer(1));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderScope(
            providers: [
              numberContainerProvider,
              numberContainerProvider,
            ],
            child: const SizedBox(),
          ),
        ),
      ),
    );
    expect(
      tester.takeException(),
      const TypeMatcher<MultipleProviderOfSameInstance>(),
    );
  });

  testWidgets('Test ProviderScope.update method', (tester) async {
    final counterProvider = Provider((_) => Signal(0));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderScope.builder(
            providers: [
              counterProvider,
            ],
            builder: (context) {
              final counter = counterProvider.observe(context).value;
              return Column(
                children: [
                  Text('$counter'),
                  ElevatedButton(
                    onPressed: () {
                      counterProvider.update(context, (value) => value + 1);
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

  testWidgets('Test ProviderScope.update method with ArgProvider',
      (tester) async {
    final counterProvider = Provider.withArg((_, int n) => Signal(n));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderScope.builder(
            providers: [
              counterProvider,
            ],
            builder: (context) {
              counterProvider.setInitialArg(0);
              final counter = counterProvider.observe(context).value;
              return Column(
                children: [
                  Text('$counter'),
                  ElevatedButton(
                    onPressed: () {
                      counterProvider.update(context, (value) => value + 1);
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

  testWidgets('Test ProviderScope multiple ancestor providers of the same Type',
      (tester) async {
    final numberContainer1Provider = Provider((_) => const NumberContainer(1));
    final numberContainer2Provider =
        Provider((_) => const NumberContainer(100));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderScope(
            providers: [
              numberContainer1Provider,
            ],
            child: ProviderScope.builder(
              providers: [
                numberContainer2Provider,
              ],
              builder: (context) {
                final numberProvider1 = numberContainer1Provider.get(context);
                final numberProvider2 = numberContainer2Provider.get(context);
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
        final r = Resource(() => Future.value(0));
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

  // todo: ProviderScopeOverride needs to override the value in a different way

  // testWidgets(
  //     'SolidOverride should override providers regardless of the hierarchy',
  //     (tester) async {
  //   final counterId = Provider<Signal<int>>(() => Signal(0));
  //   await tester.pumpWidget(
  //     ProviderScopeOverride(
  //       providers: [
  //         counterId, // todo: somehow override with 100
  //       ],
  //       child: MaterialApp(
  //         home: ProviderScope.builder(
  //           providers: [
  //             counterId,
  //           ],
  //           builder: (context) {
  //             final counter = counterId.observe(context).value;
  //             return Text(counter.toString());
  //           },
  //         ),
  //       ),
  //     ),
  //   );
  //   expect(find.text('100'), findsOneWidget);
  // });

  // testWidgets('Only one SolidOverride must be present in the widget tree',
  //     (tester) async {
  //   final counterId = Provider<Signal<int>>(() => Signal(0));
  //   await tester.pumpWidget(
  //     ProviderScopeOverride(
  //       providers: [
  //         counterId, // todo: somehow override with 100
  //       ],
  //       child: MaterialApp(
  //         home: ProviderScopeOverride.builder(
  //           providers: [
  //             counterId,
  //           ],
  //           builder: (context) {
  //             final counter = counterId.observe(context).value;
  //             return Text(counter.toString());
  //           },
  //         ),
  //       ),
  //     ),
  //   );
  //   expect(
  //     tester.takeException(),
  //     const TypeMatcher<MultipleSolidOverrideError>(),
  //   );
  // });

  // testWidgets(
  //     '''SolidOverride.of(context) throws an error if no SolidOverride is found in the widget tree''',
  //     (tester) async {
  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: Scaffold(
  //         body: Builder(
  //           builder: (context) {
  //             ProviderScopeOverride.of(context);
  //             return const SizedBox();
  //           },
  //         ),
  //       ),
  //     ),
  //   );
  //   expect(
  //     tester.takeException(),
  //     const TypeMatcher<FlutterError>(),
  //   );
  // });
}
