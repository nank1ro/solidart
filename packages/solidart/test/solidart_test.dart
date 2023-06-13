import 'dart:async';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:mockito/mockito.dart';
import 'package:solidart/src/core/computed.dart';
import 'package:solidart/src/core/effect.dart';
import 'package:solidart/src/core/read_signal.dart';
import 'package:solidart/src/core/resource.dart';
import 'package:solidart/src/core/signal.dart';
import 'package:solidart/src/core/signal_options.dart';
import 'package:solidart/src/utils.dart';
import 'package:test/test.dart';

sealed class MyEvent {}

class MyEventA implements MyEvent {
  MyEventA(this.value);

  final int value;
}

class MyEventB implements MyEvent {
  MyEventB(this.value);

  final String value;
}

class MockCallbackFunction extends Mock {
  void call();
}

class MockCallbackFunctionWithValue<T> extends Mock {
  void call(T value);
}

class _A {
  _A();
}

class _B {
  _B(this.c);
  final _C c;
}

class _C {
  _C(this.count);

  final int count;
}

@immutable
class User {
  const User({required this.id});
  final int id;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => runtimeType.hashCode ^ id.hashCode;

  @override
  String toString() => 'User(id: $id)';
}

class SampleList {
  SampleList(this.numbers);
  final List<int> numbers;
}

void main() {
  group('createSignal tests - ', () {
    test('with equals true it notifies only when the value changes', () async {
      final counter = createSignal(
        0,
        options: const SignalOptions<int>(equals: true, name: ''),
      );

      final cb = MockCallbackFunction();
      final unobserve = counter.observe((_, __) => cb());

      expect(counter(), 0);

      counter.set(1);
      await pumpEventQueue();
      expect(counter(), 1);

      counter
        ..set(2)
        ..set(2)
        ..set(2);

      await pumpEventQueue();
      counter.set(3);

      expect(counter(), 3);
      await pumpEventQueue();
      verify(cb()).called(3);
      // clear
      unobserve();
    });

    test(
        'with the identical comparator it notifies only when the comparator '
        'returns false', () async {
      final signal = createSignal(
        null,
        options: const SignalOptions<_A>(),
      );
      final cb = MockCallbackFunction();
      final unobserve = signal.observe((_, __) => cb());

      expect(signal.value, null);
      final a = _A();

      signal
        ..set(a)
        ..set(a)
        ..set(a);

      await pumpEventQueue();

      signal.set(_A());
      await pumpEventQueue();
      verify(cb()).called(2);

      // clear
      unobserve();
    });

    test('check onDispose callback fired when disposing signal', () {
      final s = createSignal(0);
      final cb = MockCallbackFunction();
      s
        ..onDispose(cb.call)
        ..dispose();
      verify(cb()).called(1);
    });

    test('observe fireImmediately works', () {
      final s = createSignal(0);
      final cb = MockCallbackFunction();
      final unobserve = s.observe(
        (previousValue, value) => cb.call(),
        fireImmediately: true,
      );
      verify(cb()).called(1);
      addTearDown(() {
        s.dispose();
        unobserve();
      });
    });

    test('check previousValue stores the previous value', () {
      final s = createSignal(0);
      expect(
        s.previousValue,
        null,
        reason: 'The signal should have a null previousValue',
      );

      s.value++;

      expect(
        s.previousValue,
        0,
        reason: 'The signal should have 0 has previousValue',
      );

      s.update((value) => value * 5);
      expect(
        s.previousValue,
        1,
        reason: 'The signal should have 1 has previousValue',
      );
    });

    test(
      'test firstWhere()',
      () async {
        final count = createSignal(0);

        unawaited(
          expectLater(count.firstWhere((value) => value > 5), completion(11)),
        );
        count
          ..set(2)
          ..set(11);
      },
      timeout: const Timeout(Duration(seconds: 1)),
    );

    test('check toString()', () {
      final s = createSignal(0);
      expect(s.toString(), startsWith('Signal<int>(value: 0'));
    });

    test('check Signal becomes ReadSignal', () {
      final s = createSignal(0);
      expect(s, const TypeMatcher<Signal<int>>());
      expect(s.toReadSignal(), const TypeMatcher<ReadSignal<int>>());
    });

    test('Signal is disposed after dispose', () {
      final s = createSignal(0);
      expect(s.disposed, false);
      s.dispose();
      expect(s.disposed, true);
    });

    test('Signal has observers', () {
      final s = createSignal(0);
      expect(s.hasObservers, false);
      createEffect((dispose) {
        s();
      });
      expect(s.hasObservers, true);
      addTearDown(s.dispose);
    });
  });

  group('createEffect tests = ', () {
    test('check effect reaction', () async {
      final signal1 = createSignal(0);
      final signal2 = createSignal(0);

      final cb = MockCallbackFunctionWithValue<int>();
      createEffect(
        (_) => cb(signal1()),
      );
      createEffect(
        (_) => cb(signal2()),
      );

      signal1.set(1);
      await pumpEventQueue();
      verify(cb(1)).called(1);
      signal1.set(2);
      await pumpEventQueue();
      verify(cb(2)).called(1);
      signal2.set(4);
      signal1.set(4);
      await pumpEventQueue();
      verify(cb(4)).called(2);
    });

    test('check effect reaction with delay', () async {
      final cb = MockCallbackFunction();
      createEffect(
        (_) => cb(),
        options: const EffectOptions(delay: Duration(milliseconds: 500)),
      );
      verifyNever(cb());
      await Future<void>.delayed(const Duration(milliseconds: 501));
      verify(cb()).called(1);
    });

    test('check effect onError', () async {
      Object? detectedError;
      createEffect(
        (_) => throw Exception(),
        onError: (error) {
          detectedError = error;
        },
      );
      expect(detectedError, isA<SolidartCaughtException>());
    });
  });

  group('signalSelector tests - ', () {
    test('check that a signal selector updates only for the selected value',
        () async {
      final klass = _B(_C(0));
      final s = createSignal(klass);
      final selected = createComputed(() => s().c.count);
      final cb = MockCallbackFunctionWithValue<int>();

      void listener() {
        cb(selected.value);
      }

      final unobserve = selected.observe((_, __) => listener());

      s.set(_B(_C(1)));
      await pumpEventQueue();

      s.set(_B(_C(5)));
      await pumpEventQueue();

      s.set(_B(_C(1)));
      await pumpEventQueue();

      verify(cb(1)).called(2);
      s.set(_B(_C(2)));
      await pumpEventQueue();
      s.set(_B(_C(2)));
      await pumpEventQueue();
      s.set(_B(_C(3)));
      await pumpEventQueue();
      verify(cb(2)).called(1);
      verify(cb(3)).called(1);

      // clear
      unobserve();
    });

    test('custom signal options for derived signal', () async {
      final a = createSignal(SampleList([1]));
      final selected = createComputed(
        () => a().numbers,
        options: SignalOptions<List<int>>(
          comparator: (a, b) => const ListEquality<int>().equals(a, b),
        ),
      );

      final cb = MockCallbackFunction();
      selected.observe((previousValue, value) => cb.call());

      verifyNever(cb());

      a.set(SampleList([1]));
      await pumpEventQueue();
      verifyNever(cb());

      a.set(SampleList([1, 2]));
      await pumpEventQueue();
      verify(cb()).called(1);
    });

    test("selector's readable signal contains previous value", () async {
      final signal = createSignal(0);
      final derived = createComputed(() => signal() * 2);
      expect(derived.previousValue, null);

      signal.set(1);
      await pumpEventQueue();
      expect(derived.previousValue, 0);

      signal.set(2);
      await pumpEventQueue();
      expect(derived.previousValue, 2);

      signal.set(1);
      await pumpEventQueue();
      expect(derived.previousValue, 4);
    });

    test('derived signal disposes', () async {
      final count = createSignal(0);
      final doubleCount = createComputed(() => count() * 2);
      expect(doubleCount.disposed, false);
      doubleCount.dispose();
      expect(doubleCount.disposed, true);
    });

    test('check derived signal that throws', () async {
      final count = createSignal(1);
      final doubleCount = createComputed(
        () {
          if (count() == 1) {
            return count() * 2;
          }
          return throw Exception();
        },
      );

      count.value = 3;
      expect(
        () => doubleCount.value,
        throwsA(const TypeMatcher<SolidartCaughtException>()),
      );
    });
  });

  group('ReadSignal tests', () {
    test('check ReadSignal value and listener count', () {
      final s = ReadSignal(0);
      expect(s.value, 0);
      expect(s.previousValue, null);
      expect(s.listenerCount, 0);

      createEffect((_) {
        s();
      });
      expect(s.listenerCount, 1);
    });

    test('check toString()', () {
      final s = ReadSignal(0);
      expect(s.toString(), startsWith('ReadSignal<int>(value: 0'));
    });
  });

  group('Resource tests', () {
    test('check createResource with stream', () async {
      final streamController = StreamController<int>();
      addTearDown(streamController.close);

      final resource = createResource(stream: streamController.stream);
      expect(resource.state, isA<ResourceUnresolved<int>>());
      resource.resolve().ignore();
      expect(resource.state, isA<ResourceLoading<int>>());
      streamController.add(1);
      await pumpEventQueue();
      expect(resource.state, isA<ResourceReady<int>>());
      expect(resource.state.value, 1);

      streamController.add(10);
      await pumpEventQueue();
      expect(resource.state, isA<ResourceReady<int>>());
      expect(resource.state(), 10);

      streamController.addError(UnimplementedError());
      await pumpEventQueue();
      expect(resource.state, isA<ResourceError<int>>());
      expect(resource.state.error, isUnimplementedError);
    });

    test('check createResource with future that throws', () async {
      Future<User> getUser() => throw Exception();
      final resource = createResource<User>(
        fetcher: getUser,
        options: const ResourceOptions(lazy: false),
      );

      addTearDown(resource.dispose);

      await pumpEventQueue();
      expect(resource.state, isA<ResourceError<User>>());
      expect(resource.state.error, isException);
    });

    test('check createResource with future', () async {
      final userId = createSignal(0);

      Future<User> getUser() {
        if (userId() == 2) throw Exception();
        return Future.value(User(id: userId()));
      }

      final resource = createResource(fetcher: getUser, source: userId);

      await resource.resolve();
      await pumpEventQueue();
      expect(resource.state, isA<ResourceReady<User>>());
      expect(resource.state.value, const User(id: 0));

      userId.set(1);
      await pumpEventQueue();
      expect(resource.state, isA<ResourceReady<User>>());
      expect(resource.state(), const User(id: 1));

      userId.set(2);
      await pumpEventQueue();
      expect(resource.state, isA<ResourceError<User>>());
      expect(resource.state.error, isException);

      userId.set(3);
      await pumpEventQueue();
      await resource.refetch();
      expect(resource.state, isA<ResourceReady<User>>());
      expect(resource.state.hasError, false);
      expect(resource.state.asError, isNull);
      expect(resource.state.isLoading, false);
      expect(resource.state.asReady, isNotNull);
      expect(resource.state.isReady, true);

      resource.state.on(
        ready: (data, refreshing) {},
        error: (error, stack, refreshing) {},
        loading: () {},
      );

      resource.dispose();
    });

    test('check ResourceState.on', () async {
      var shouldThrow = false;
      Future<int> fetcher() {
        return Future.delayed(const Duration(milliseconds: 150), () {
          if (shouldThrow) throw Exception();
          return 0;
        });
      }

      var dataCalledTimes = 0;
      var loadingCalledTimes = 0;
      var errorCalledTimes = 0;
      var refreshingOnDataTimes = 0;
      var refreshingOnErrorTimes = 0;
      final resource = createResource(fetcher: fetcher);
      resource.resolve().ignore();

      createEffect(
        (_) {
          resource.state.on(
            ready: (data, refreshing) {
              if (refreshing) {
                refreshingOnDataTimes++;
              } else {
                dataCalledTimes++;
              }
            },
            error: (error, stackTrace, refreshing) {
              if (refreshing) {
                refreshingOnErrorTimes++;
              } else {
                errorCalledTimes++;
              }
            },
            loading: () {
              loadingCalledTimes++;
            },
          );
        },
      );

      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(loadingCalledTimes, 1);
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(dataCalledTimes, 1);
      expect(errorCalledTimes, 0);

      resource.refetch().ignore();
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(refreshingOnDataTimes, 1);
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(dataCalledTimes, 2);

      expect(resource.state, const TypeMatcher<ResourceReady<int>>());
      shouldThrow = true;
      resource.refetch().ignore();
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(errorCalledTimes, 1);
      expect(refreshingOnErrorTimes, 0);

      resource.refetch().ignore();
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(refreshingOnErrorTimes, 1);
      expect(errorCalledTimes, 2);

      shouldThrow = false;
      resource.refetch().ignore();
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(refreshingOnErrorTimes, 2);
      expect(errorCalledTimes, 2);
      expect(dataCalledTimes, 3);

      expect(loadingCalledTimes, 1);
    });

    test(
      'test firstWhereReady()',
      () async {
        Future<int> fetcher() => Future.delayed(
              const Duration(milliseconds: 300),
              () => 1,
            );
        final count = createResource(fetcher: fetcher);
        count.resolve().ignore();

        await expectLater(count.firstWhereReady(), completion(1));
      },
      timeout: const Timeout(Duration(seconds: 1)),
    );

    test('check toString()', () async {
      final r = createResource(fetcher: () => Future.value(1));
      await r.resolve();
      await pumpEventQueue();
      expect(
        r.toString(),
        startsWith(
          '''Resource<int>(state: ResourceReady<int>(value: 1, refreshing: false)''',
        ),
      );
    });
  });

  group('ReactiveContext tests', () {
    test('throws Exception for reactions that do not converge', () {
      var firstTime = true;
      final count = createSignal(0);
      final d = createEffect((_) {
        // watch count
        count.value;
        if (firstTime) {
          firstTime = false;
          return;
        }

        // cyclic-dependency
        // this effect will keep on getting triggered as count.value keeps
        // changing every time it's invoked
        count.value = count.value + 1;
      });

      expect(
        () => count.value = 1,
        throwsA(const TypeMatcher<SolidartReactionException>()),
      );
      d();
    });
  });
}
