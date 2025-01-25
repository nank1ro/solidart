// ignore_for_file: lines_longer_than_80_chars

import 'dart:async';

import 'package:disco/disco.dart';
import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
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

  testWidgets('SignalBuilder works properly (1 Signal)', (tester) async {
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

  testWidgets('SignalBuilder works properly (2 Signals)', (tester) async {
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

  testWidgets('SignalBuilder works properly (3 Signals)', (tester) async {
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

  group('Provider and SignalBuilder', () {
    testWidgets(
        '(Provider) SignalBuilder works properly (1 Signal and 1 Computed)',
        (tester) async {
      final s = Signal(0);

      final counterProvider = Provider((_) => s);
      final doubleCounterProvider = Provider((_) => Computed(() => s() * 2));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProviderScope(
              providers: [
                counterProvider,
                doubleCounterProvider,
              ],
              child: SignalBuilder(
                builder: (context, child) {
                  final counter = counterProvider.of(context).value;
                  final doubleCounter = doubleCounterProvider.of(context).value;
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

    testWidgets('(Provider) SignalBuilder works properly (1 Computed)',
        (tester) async {
      final s = Signal(0);

      final doubleCounterProvider = Provider((_) => Computed(() => s() * 2));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProviderScope(
              providers: [
                doubleCounterProvider,
              ],
              child: SignalBuilder(
                builder: (context, child) {
                  final doubleCounter = doubleCounterProvider.of(context).value;
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

    testWidgets('(Provider) SignalBuilder works properly (1 ReadSignal)',
        (tester) async {
      final s = Signal(0);

      final counterProvider = Provider((_) => s.toReadSignal());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProviderScope(
              providers: [
                counterProvider,
              ],
              child: SignalBuilder(
                builder: (context, child) {
                  final counter = counterProvider.of(context).value;
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

  testWidgets('(Provider) SignalBuilder works properly (1 Signal, 1 Computed)',
      (tester) async {
    final s = Signal(0);
    final s2 = Computed(() => s() * 2);

    final counterProvider = Provider((_) => s);
    final doubleCounterProvider = Provider((_) => s2);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderScope(
            providers: [
              counterProvider,
              doubleCounterProvider,
            ],
            child: SignalBuilder(
              builder: (context, _) {
                final counter = counterProvider.of(context);
                final doubleCounter = doubleCounterProvider.of(context);
                return Text('${counter()} ${doubleCounter()}');
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

  testWidgets('Signal reactivity within Provider create fn', (tester) async {
    final s = Signal(0);
    final counterProvider = Provider((_) => s);

    final doubleCounterProvider = Provider((context) {
      final counter = counterProvider.of(context);
      return Computed(() => counter() * 2);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderScope(
            providers: [counterProvider],
            child: ProviderScope(
              providers: [doubleCounterProvider],
              child: SignalBuilder(
                builder: (context, _) {
                  final counter = counterProvider.of(context);
                  final doubleCounter = doubleCounterProvider.of(context);
                  return Text('${counter()} ${doubleCounter()}');
                },
              ),
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

  group('ProviderScopePortal with Signals', () {
    testWidgets('ProviderScopePortal with 1 Signal w/out autoDispose',
        (tester) async {
      final s = Signal(0, autoDispose: false);
      final counterProvider = Provider((_) => s);

      Future<void> showCounterDialog({required BuildContext context}) {
        return showDialog(
          context: context,
          builder: (_) {
            return ProviderScopePortal(
              mainContext: context,
              child: SignalBuilder(
                builder: (innerContext, child) {
                  final counter = counterProvider.of(innerContext).value;
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
            body: ProviderScope(
              providers: [counterProvider],
              child: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showCounterDialog(context: context);
                  },
                  child: const Text('show dialog'),
                ),
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

    testWidgets('ProviderScopePortal with 1 Signal and 1 Computed',
        (tester) async {
      final s = Signal(0);
      final counterProvider = Provider((_) => s);
      final doubleCounterProvider = Provider((_) => Computed(() => s() * 2));

      Future<void> showCounterDialog({required BuildContext context}) {
        return showDialog(
          context: context,
          builder: (dialogContext) {
            return ProviderScopePortal(
              mainContext: context,
              child: Builder(
                builder: (innerContext) {
                  return SignalBuilder(
                    builder: (_, __) {
                      final counter = counterProvider.of(innerContext);
                      final doubleCounter =
                          doubleCounterProvider.of(innerContext);
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
            body: ProviderScope(
              providers: [
                counterProvider,
                doubleCounterProvider,
              ],
              child: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showCounterDialog(context: context);
                  },
                  child: const Text('show dialog'),
                ),
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
  });

  testWidgets('(Provider) Signal.updateValue method', (tester) async {
    final counterProvider = Provider((_) => Signal(0));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderScope(
            providers: [
              counterProvider,
            ],
            child: SignalBuilder(
              builder: (context, child) {
                final counter = counterProvider.of(context);
                return Column(
                  children: [
                    Text('${counter.value}'),
                    ElevatedButton(
                      onPressed: () {
                        counter.updateValue((value) => value + 1);
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

  testWidgets('(ArgProvider) Signal.updateValue method', (tester) async {
    final counterProvider = Provider.withArgument((_, int n) => Signal(n));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderScope(
            providers: [
              counterProvider(0),
            ],
            child: SignalBuilder(
              builder: (context, _) {
                final counter = counterProvider.of(context);
                return Column(
                  children: [
                    Text('${counter.value}'),
                    ElevatedButton(
                      onPressed: () {
                        counter.updateValue((value) => value + 1);
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

  // TODO(nank1ro): place this test as first and see if it still compromises all the rest (if so, investigate Effect) (NB: I added a similar test in disco and it does not cause the reactivity problem we have noticed here)
  testWidgets('(Provider) Not found signal throws an error', (tester) async {
    final counterProvider = Provider((_) => Signal(0));
    final invalidCounterProvider = Provider((_) => Signal(0));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderScope(
            providers: [
              counterProvider,
            ],
            child: SignalBuilder(
              builder: (context, _) {
                final counter = invalidCounterProvider.of(context);
                return Text(counter().toString());
              },
            ),
          ),
        ),
      ),
    );
    expect(
      tester.takeException(),
      const TypeMatcher<SolidartCaughtException>().having(
        (error) => (error.exception as ProviderWithoutScopeError).provider,
        'Matching the wrong ID should result in a ProviderError.',
        equals(invalidCounterProvider),
      ),
    );
  });
}
