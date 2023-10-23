import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:mockito/mockito.dart';
import 'package:solidart/src/core/core.dart';
import 'package:solidart/src/extensions.dart';
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
  group(
    'Signal tests - ',
    () {
      test('with equals true it notifies only when the value changes',
          () async {
        final counter = Signal(
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
        final signal = Signal(
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
        final s = Signal(0);
        final cb = MockCallbackFunction();
        s
          ..onDispose(cb.call)
          ..dispose();
        verify(cb()).called(1);
      });

      test('observe fireImmediately works', () {
        final s = Signal(0);
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
        final s = Signal(0);
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

        s.updateValue((value) => value * 5);
        expect(
          s.previousValue,
          1,
          reason: 'The signal should have 1 has previousValue',
        );
      });

      test('test firstWhere()', () async {
        final count = Signal(0);

        unawaited(
          expectLater(count.until((value) => value > 5), completion(11)),
        );
        count
          ..set(2)
          ..set(11);
      });

      test('check toString()', () {
        final s = Signal(0);
        expect(s.toString(), startsWith('Signal<int>(value: 0'));
      });

      test('check Signal becomes ReadSignal', () {
        final s = Signal(0);
        expect(s, const TypeMatcher<Signal<int>>());
        expect(s.toReadSignal(), const TypeMatcher<ReadSignal<int>>());
      });

      test('Signal is disposed after dispose', () {
        final s = Signal(0);
        expect(s.disposed, false);
        s.dispose();
        expect(s.disposed, true);
      });

      test('Signal has observers', () {
        final s = Signal(0);
        expect(s.hasObservers, false);
        Effect((dispose) {
          s();
        });
        expect(s.hasObservers, true);
        addTearDown(s.dispose);
      });

      test('Signal<bool> toggle', () {
        final signal = Signal(false);
        expect(signal(), false);
        signal.toggle();
        expect(signal(), true);
      });
    },
    timeout: const Timeout(Duration(seconds: 1)),
  );

  group(
    'Effect tests = ',
    () {
      test('check effect reaction', () async {
        final signal1 = Signal(0);
        final signal2 = Signal(0);

        final cb = MockCallbackFunctionWithValue<int>();
        Effect(
          (_) => cb(signal1()),
        );
        Effect(
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
        Effect(
          (_) => cb(),
          options: const EffectOptions(delay: Duration(milliseconds: 500)),
        );
        verifyNever(cb());
        await Future<void>.delayed(const Duration(milliseconds: 501));
        verify(cb()).called(1);
      });

      test('check effect onError', () async {
        Object? detectedError;
        Effect(
          (_) => throw Exception(),
          onError: (error) {
            detectedError = error;
          },
        );
        expect(detectedError, isA<SolidartCaughtException>());
      });
    },
    timeout: const Timeout(Duration(seconds: 1)),
  );

  group(
    'signalSelector tests - ',
    () {
      test('check that a signal selector updates only for the selected value',
          () async {
        final klass = _B(_C(0));
        final s = Signal(klass);
        final selected = Computed(() => s().c.count);
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
        final a = Signal(SampleList([1]));
        final selected = Computed(
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
        final signal = Signal(0);
        final derived = Computed(() => signal() * 2);
        await pumpEventQueue();
        expect(derived.hasPreviousValue, false);
        expect(derived.previousValue, null);

        signal.set(1);
        await pumpEventQueue();
        expect(derived.hasPreviousValue, true);
        expect(derived.previousValue, 0);

        signal.set(2);
        await pumpEventQueue();
        expect(derived.hasPreviousValue, true);
        expect(derived.previousValue, 2);

        signal.set(1);
        await pumpEventQueue();
        expect(derived.hasPreviousValue, true);
        expect(derived.previousValue, 4);
      });

      test('signal has previous value', () {
        final s = Signal(0);
        expect(s.hasPreviousValue, false);
        s.set(1);
        expect(s.hasPreviousValue, true);
      });

      test('nullable derived signal', () async {
        final count = Signal<int?>(0);
        final doubleCount = Computed(() {
          if (count() == null) return null;
          return count()! * 2;
        });

        await pumpEventQueue();
        expect(doubleCount.value, 0);

        count.set(1);
        await pumpEventQueue();
        expect(doubleCount.value, 2);

        count.set(null);
        await pumpEventQueue();
        expect(doubleCount.value, null);
      });

      test('derived signal disposes', () async {
        final count = Signal(0);
        final doubleCount = Computed(() => count() * 2);
        expect(doubleCount.disposed, false);
        doubleCount.dispose();
        expect(doubleCount.disposed, true);
      });

      test('check derived signal that throws', () async {
        final count = Signal(1);
        final doubleCount = Computed(
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

      test('check toString', () {
        final count = Signal(1);
        final doubleCount = Computed(() => count() * 2);

        expect(doubleCount.toString(), startsWith('Computed<int>(value: 2'));
      });
    },
    timeout: const Timeout(Duration(seconds: 1)),
  );

  group(
    'ReadSignal tests',
    () {
      test('check ReadSignal value and listener count', () {
        final s = ReadSignal(0);
        expect(s.value, 0);
        expect(s.previousValue, null);
        expect(s.listenerCount, 0);

        Effect((_) {
          s();
        });
        expect(s.listenerCount, 1);
      });

      test('check toString()', () {
        final s = ReadSignal(0);
        expect(s.toString(), startsWith('ReadSignal<int>(value: 0'));
      });
    },
    timeout: const Timeout(Duration(seconds: 1)),
  );

  group(
    'Resource tests',
    () {
      test('check Resource with stream', () async {
        final streamController = StreamController<int>();
        addTearDown(streamController.close);

        final resource = Resource(stream: () => streamController.stream);
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

      test('check Resource with stream and source', () async {
        final count = Signal(-1);

        final resource = Resource(
          stream: () {
            if (count() < 1) return Stream.value(0);
            return Stream.value(count());
          },
          source: count,
          options: const ResourceOptions(lazy: false),
        );

        addTearDown(() {
          resource.dispose();
          count.dispose();
        });

        await pumpEventQueue();
        expect(
          resource.state,
          isA<ResourceReady<int>>().having((p0) => p0.value, 'equal to 0', 0),
        );

        count.set(5);
        await pumpEventQueue();
        expect(
          resource.state,
          isA<ResourceReady<int>>().having((p0) => p0.value, 'equal to 5', 5),
        );
      });

      test('check Resource with changing stream', () async {
        final streamControllerA = StreamController<int>();
        final streamControllerB = StreamController<int>();
        final source = Signal(0);
        addTearDown(() {
          streamControllerA.close();
          streamControllerB.close();
          source.dispose();
        });

        final resource = Resource(
          stream: () {
            if (source().isEven) {
              return streamControllerA.stream;
            }
            return streamControllerB.stream;
          },
          source: source,
        );
        expect(resource.state, isA<ResourceLoading<int>>());
        streamControllerA.add(1);
        await pumpEventQueue();
        expect(resource.state, isA<ResourceReady<int>>());
        expect(resource.state.value, 1);

        // changing to stream B
        source.set(1);
        expect(
          resource.state,
          isA<ResourceReady<int>>()
              .having((p0) => p0.isRefreshing, 'Should be refreshing', true),
        );

        // add to stream A, the value should not be propagated
        // because we're listening to stream B
        streamControllerA.add(2);
        await pumpEventQueue();
        expect(resource.state.value, 1);

        streamControllerA.add(3);
        source.set(2);
        await pumpEventQueue();
        expect(resource.state.value, 3);
      });

      test('check Resource with future that throws', () async {
        Future<User> getUser() => throw Exception();
        final resource = Resource<User>(
          fetcher: getUser,
          options: const ResourceOptions(lazy: false),
        );

        addTearDown(resource.dispose);

        await pumpEventQueue();
        expect(resource.state, isA<ResourceError<User>>());
        expect(resource.state.error, isException);
      });

      test('check Resource with future', () async {
        final userId = Signal(0);

        Future<User> getUser() {
          if (userId() == 2) throw Exception();
          return Future.value(User(id: userId()));
        }

        final resource = Resource(
          fetcher: getUser,
          source: userId,
          options: const ResourceOptions(lazy: false),
        );

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
        await resource.refresh();
        expect(resource.state, isA<ResourceReady<User>>());
        expect(resource.state.hasError, false);
        expect(resource.state.asError, isNull);
        expect(resource.state.isLoading, false);
        expect(resource.state.asReady, isNotNull);
        expect(resource.state.isReady, true);

        resource.dispose();
      });

      test('update ResourceState', () async {
        Future<int> fetcher() => Future.value(1);
        final resource = Resource(fetcher: fetcher);
        expect(resource.state, isA<ResourceLoading<int>>());
        await pumpEventQueue();
        expect(
          resource.state,
          isA<ResourceReady<int>>()
              .having((p0) => p0.value, 'value equal to 1', 1),
        );

        resource.update((state) => const ResourceReady(2));
        expect(
          resource.state,
          isA<ResourceReady<int>>()
              .having((p0) => p0.value, 'value equal to 2', 2),
        );
      });
      test('refresh Resource with fetcher while loading', () async {
        Future<int> fetcher() => Future.delayed(
              const Duration(milliseconds: 200),
              () => 1,
            );
        final resource = Resource(fetcher: fetcher);
        expect(resource.state, isA<ResourceLoading<int>>());
        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(resource.state, isA<ResourceLoading<int>>());

        resource.refresh().ignore();
        expect(resource.state, isA<ResourceLoading<int>>());

        await Future<void>.delayed(const Duration(milliseconds: 200));
        expect(resource.state, isA<ResourceReady<int>>());
      });
      test('refresh Resource with stream while loading', () async {
        final controller = StreamController<int>();
        final resource = Resource(stream: () => controller.stream);
        expect(resource.state, isA<ResourceLoading<int>>());

        await resource.refresh();
        expect(resource.state, isA<ResourceLoading<int>>());

        controller.add(1);
        await pumpEventQueue();
        expect(resource.state, isA<ResourceReady<int>>());
      });
      test('check ResourceSelector with future', () async {
        final userId = Signal(0);

        Future<User> getUser() {
          if (userId() == 2) throw Exception();
          return Future.value(User(id: userId()));
        }

        final resource = Resource(fetcher: getUser, source: userId);
        final idResource = resource.select((data) => data.id);

        await pumpEventQueue();
        expect(idResource.state, isA<ResourceReady<int>>());
        expect(idResource.state.value, 0);

        userId.set(1);
        await pumpEventQueue();
        expect(idResource.state, isA<ResourceReady<int>>());
        expect(idResource.state(), 1);

        userId.set(2);
        await pumpEventQueue();
        expect(idResource.state, isA<ResourceError<int>>());
        expect(idResource.state.error, isException);

        userId.set(3);
        await pumpEventQueue();
        await idResource.refresh();
        expect(idResource.state, isA<ResourceReady<int>>());
        expect(idResource.state.hasError, false);
        expect(idResource.state.asError, isNull);
        expect(idResource.state.isLoading, false);
        expect(idResource.state.asReady, isNotNull);
        expect(idResource.state.isReady, true);

        resource.dispose();
        expect(idResource.disposed, true);
      });

      test('check ResourceSelector with stream', () async {
        final userId = Signal(0);

        Stream<User> getUser() {
          if (userId() == 2) return Stream<User>.error(Exception());
          return Stream.value(User(id: userId()));
        }

        final resource = Resource(stream: getUser, source: userId);
        final idResource = resource.select((data) => data.id);

        await pumpEventQueue();
        expect(idResource.state, isA<ResourceReady<int>>());
        expect(idResource.state.value, 0);

        userId.set(1);
        await pumpEventQueue();
        expect(idResource.state, isA<ResourceReady<int>>());
        expect(idResource.state(), 1);

        userId.set(2);
        await pumpEventQueue();
        expect(idResource.state, isA<ResourceError<int>>());
        expect(idResource.state.error, isException);

        userId.set(3);
        await pumpEventQueue();
        await idResource.refresh();
        expect(idResource.state, isA<ResourceReady<int>>());
        expect(idResource.state.hasError, false);
        expect(idResource.state.asError, isNull);
        expect(idResource.state.isLoading, false);
        expect(idResource.state.asReady, isNotNull);
        expect(idResource.state.isReady, true);

        resource.dispose();
        expect(idResource.disposed, true);
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
        final resource = Resource(fetcher: fetcher);

        Effect(
          (_) {
            resource.state.on(
              ready: (data) {
                if (resource.state.isRefreshing) {
                  refreshingOnDataTimes++;
                } else {
                  dataCalledTimes++;
                }
              },
              error: (error, stackTrace) {
                if (resource.state.isRefreshing) {
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

        resource.refresh().ignore();
        await Future<void>.delayed(const Duration(milliseconds: 40));
        expect(refreshingOnDataTimes, 1);
        await Future<void>.delayed(const Duration(milliseconds: 150));
        expect(dataCalledTimes, 2);

        expect(resource.state, const TypeMatcher<ResourceReady<int>>());
        shouldThrow = true;
        resource.refresh().ignore();
        await Future<void>.delayed(const Duration(milliseconds: 150));
        expect(errorCalledTimes, 1);
        expect(refreshingOnErrorTimes, 0);

        resource.refresh().ignore();
        await Future<void>.delayed(const Duration(milliseconds: 150));
        expect(refreshingOnErrorTimes, 1);
        expect(errorCalledTimes, 2);

        shouldThrow = false;
        resource.refresh().ignore();
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
          final count = Resource(fetcher: fetcher);

          await expectLater(count.untilReady(), completion(1));
        },
      );

      test('check toString()', () async {
        final r = Resource(
          fetcher: () => Future.value(1),
          options: const ResourceOptions(lazy: false),
        );
        await pumpEventQueue();
        expect(
          r.toString(),
          startsWith(
            '''Resource<int>(state: ResourceReady<int>(value: 1, refreshing: false)''',
          ),
        );
      });
    },
    timeout: const Timeout(Duration(seconds: 1)),
  );

  group(
    'ReactiveContext tests',
    () {
      test('throws Exception for reactions that do not converge', () {
        var firstTime = true;
        final count = Signal(0);
        final d = Effect((_) {
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
    },
    timeout: const Timeout(Duration(seconds: 1)),
  );

  group(
    'ListSignal tests',
    () {
      test('check length', () {
        final list = ListSignal([1, 2]);
        expect(list.length, 2);
        list.add(3);
        expect(list.length, 3);
      });

      test('change length', () {
        final list = ListSignal<int?>([1, 2]);
        expect(list.length, 2);
        list.length = 3;
        expect(list.length, 3);
        expect(const ListEquality<int?>().equals(list, [1, 2, null]), true);
      });

      test('check elementAt', () {
        final list = ListSignal([1, 2]);
        expect(list.elementAt(0), 1);
        expect(list.elementAt(1), 2);
        expect(() => list.elementAt(2), throwsRangeError);

        list.add(3);
        expect(list.elementAt(2), 3);
      });

      test('check operator +', () {
        final list = ListSignal([1, 2]);
        expect(list + [3, 4], [1, 2, 3, 4]);
      });

      test('check operator []', () {
        final list = ListSignal([1, 2]);
        expect(list[0], 1);
        expect(list[1], 2);
        expect(() => list[2], throwsRangeError);

        list.add(3);
        expect(list[2], 3);
      });

      test('check operator []=', () {
        final list = ListSignal([1, 2]);
        expect(list[0], 1);
        expect(list[1], 2);
        list[0] = 3;
        expect(list[0], 3);
        list[1] = 4;
        expect(list[1], 4);
      });

      test('check add', () {
        final list = ListSignal([1, 2]);
        expect(list, [1, 2]);
        list.add(3);
        expect(list, [1, 2, 3]);
      });

      test('check addAll', () {
        final list = ListSignal([1, 2]);
        expect(list, [1, 2]);
        list.addAll([3, 4]);
        expect(list, [1, 2, 3, 4]);
      });

      test('check single', () {
        final list = ListSignal([1]);
        expect(list.single, 1);
        list.add(3);
        expect(() => list.single, throwsStateError);
      });

      test('check first', () {
        final list = ListSignal([1, 2]);
        expect(list.first, 1);

        list.add(3);
        expect(list.first, 1);

        list[0] = 4;
        expect(list.first, 4);
      });

      test('check last', () {
        final list = ListSignal([1, 2]);
        expect(list.last, 2);

        list.add(3);
        expect(list.last, 3);

        list[2] = 4;
        expect(list.last, 4);
      });

      test('check singleWhere', () {
        final list = ListSignal([1, 2]);
        expect(list.singleWhere((e) => e == 1), 1);
        expect(() => list.singleWhere((e) => e == 4), throwsStateError);
      });

      test('check firstWhere', () {
        final list = ListSignal([1, 2]);
        expect(list.firstWhere((e) => e == 1), 1);
        expect(() => list.firstWhere((e) => e == 4), throwsStateError);
      });

      test('check lastWhere', () {
        final list = ListSignal([1, 2]);
        expect(list.lastWhere((e) => e == 1), 1);
        expect(() => list.lastWhere((e) => e == 4), throwsStateError);
      });

      test('check lastIndexWhere', () {
        final list = ListSignal([1, 2]);
        expect(list.lastIndexWhere((e) => e == 1), 0);
        expect(list.lastIndexWhere((e) => e == 4), -1);
      });

      test('check isEmpty', () {
        final list = ListSignal([1, 2]);
        expect(list.isEmpty, false);
        list.clear();
        expect(list.isEmpty, true);
      });

      test('check isNotEmpty', () {
        final list = ListSignal([1, 2]);
        expect(list.isNotEmpty, true);
        list.clear();
        expect(list.isNotEmpty, false);
      });

      test('check clear', () {
        final list = ListSignal([1, 2]);
        expect(list, [1, 2]);
        list.clear();
        expect(list, isEmpty);
      });

      test('check remove', () {
        final list = ListSignal([1, 2]);
        expect(list, [1, 2]);
        list.remove(1);
        expect(list, [2]);
      });

      test('check removeAt', () {
        final list = ListSignal([1, 2]);
        expect(list, [1, 2]);
        list.removeAt(0);
        expect(list, [2]);
      });

      test('check removeWhere', () {
        final list = ListSignal([1, 2, 1]);
        expect(list, [1, 2, 1]);
        list.removeWhere((e) => e == 1);
        expect(list, [2]);
      });

      test('check retainWhere', () {
        final list = ListSignal([1, 2, 1]);
        expect(list, [1, 2, 1]);

        list.retainWhere((e) => e == 1);
        expect(list, [1, 1]);
      });

      test('check setAll', () {
        final list = ListSignal([1, 2]);
        expect(list, [1, 2]);
        list.setAll(0, [3, 4]);
        expect(list, [3, 4]);
      });

      test('check setRange', () {
        final list1 = ListSignal([1, 2, 3, 4]);
        final list2 = [5, 6, 7, 8, 9];

        const skipCount = 3;
        list1.setRange(1, 3, list2, skipCount);
        expect(list1, [1, 8, 9, 4]);
      });

      test('check replaceRange', () {
        final list = ListSignal([1, 2, 3, 4, 5]);
        final replacements = [6, 7];
        list.replaceRange(1, 4, replacements);
        expect(list, [1, 6, 7, 5]);
      });

      test('check fillRange', () {
        final list = ListSignal([1, 2, 3, 4, 5]);
        expect(list, [1, 2, 3, 4, 5]);
        list.fillRange(1, 4, 6);
        expect(list, [1, 6, 6, 6, 5]);
      });

      test('check sort', () {
        final list = ListSignal([3, 1, 2, 4]);
        expect(list, [3, 1, 2, 4]);
        list.sort((a, b) => a.compareTo(b));
        expect(list, [1, 2, 3, 4]);
      });

      test('check sublist', () {
        final list = ListSignal([1, 2, 3, 4]);
        expect(list.sublist(1, 3), [2, 3]);
      });

      test('check toList', () {
        final list = ListSignal([1, 2]);
        expect(list.toList(growable: false), [1, 2]);
      });

      test('check cast', () {
        final list = ListSignal([1, 2]);
        expect(list.cast<int>(), [1, 2]);
      });

      test('check toString', () {
        final list = ListSignal([1, 2]);
        expect(list.toString(), startsWith('ListSignal<int>(value: [1, 2]'));
      });

      test('check set first', () {
        final list = ListSignal([1, 2]);
        expect(list, [1, 2]);
        list.first = 3;
        expect(list, [3, 2]);
      });

      test('check set last', () {
        final list = ListSignal([1, 2]);
        expect(list, [1, 2]);
        list.last = 3;
        expect(list, [1, 3]);
      });

      test('check insert', () {
        final list = ListSignal([1, 2]);
        expect(list, [1, 2]);
        list.insert(0, 3);
        expect(list, [3, 1, 2]);
      });

      test('check insertAll', () {
        final list = ListSignal([1, 2]);
        expect(list, [1, 2]);
        list.insertAll(0, [3, 4]);
        expect(list, [3, 4, 1, 2]);
      });

      test('check removeLast', () {
        final list = ListSignal([1, 2]);
        expect(list, [1, 2]);
        list.removeLast();
        expect(list, [1]);
      });

      test('check removeRange', () {
        final list = ListSignal([1, 2, 3, 4]);
        expect(list, [1, 2, 3, 4]);
        list.removeRange(1, 3);
        expect(list, [1, 4]);
      });

      test('check shuffle', () {
        final list = ListSignal([1, 2]);
        expect(list, [1, 2]);
        list.shuffle(_AlwaysZeroRandom());
        expect(list, [2, 1]);
      });

      test('check set', () {
        final list = ListSignal([1, 2]);
        expect(list, [1, 2]);
        list.set([3, 4]);
        expect(list, [3, 4]);
      });

      test('check set with equals', () {
        final list = ListSignal<int>(
          [1, 2],
          options: const SignalOptions(equals: true),
        );
        expect(list, [1, 2]);
        list.set([3, 4]);
        expect(list, [3, 4]);
      });

      test('check updateValue', () {
        final list = ListSignal([1, 2]);
        expect(list, [1, 2]);
        list.updateValue((v) => v..add(3));
        expect(list, [1, 2, 3]);
      });
    },
    timeout: const Timeout(Duration(seconds: 1)),
  );

  group(
    'SetSignal tests',
    () {
      test('check length', () {
        final set = SetSignal({1, 2});
        expect(set.length, 2);
        set.add(3);
        expect(set.length, 3);
      });

      test('check elementAt', () {
        final set = SetSignal({1, 2});
        expect(set.elementAt(0), 1);
        expect(set.elementAt(1), 2);
        expect(() => set.elementAt(2), throwsRangeError);

        set.add(3);
        expect(set.elementAt(2), 3);
      });

      test('check add', () {
        final set = SetSignal({1, 2});
        expect(set, [1, 2]);
        set.add(3);
        expect(set, [1, 2, 3]);
      });

      test('check addAll', () {
        final set = SetSignal({1, 2});
        expect(set, [1, 2]);
        set.addAll([3, 4]);
        expect(set, [1, 2, 3, 4]);
      });

      test('check single', () {
        final set = SetSignal({1});
        expect(set.single, 1);
        set.add(3);
        expect(() => set.single, throwsStateError);
      });

      test('check first', () {
        final set = SetSignal({1, 2});
        expect(set.first, 1);

        set.remove(1);
        expect(set.first, 2);
      });

      test('check last', () {
        final set = SetSignal({1, 2});
        expect(set.last, 2);

        set.add(3);
        expect(set.last, 3);
      });

      test('check singleWhere', () {
        final set = SetSignal({1, 2});
        expect(set.singleWhere((e) => e == 1), 1);
        expect(() => set.singleWhere((e) => e == 4), throwsStateError);
      });

      test('check firstWhere', () {
        final set = SetSignal({1, 2});
        expect(set.firstWhere((e) => e == 1), 1);
        expect(() => set.firstWhere((e) => e == 4), throwsStateError);
      });

      test('check lastWhere', () {
        final set = SetSignal({1, 2});
        expect(set.lastWhere((e) => e == 1), 1);
        expect(() => set.lastWhere((e) => e == 4), throwsStateError);
      });

      test('check isEmpty', () {
        final set = SetSignal({1, 2});
        expect(set.isEmpty, false);
        set.clear();
        expect(set.isEmpty, true);
      });

      test('check isNotEmpty', () {
        final set = SetSignal({1, 2});
        expect(set.isNotEmpty, true);
        set.clear();
        expect(set.isNotEmpty, false);
      });

      test('check clear', () {
        final set = SetSignal({1, 2});
        expect(set, [1, 2]);
        set.clear();
        expect(set, isEmpty);
      });

      test('check remove', () {
        final set = SetSignal({1, 2});
        expect(set, [1, 2]);
        set.remove(1);
        expect(set, [2]);
      });

      test('check removeWhere', () {
        final set = SetSignal({1, 2, 3});
        expect(set, {1, 2, 3});
        set.removeWhere((e) => e == 1);
        expect(set, {2, 3});
      });

      test('check retainWhere', () {
        final set = SetSignal({
          1,
          2,
        });
        expect(set, {1, 2});

        set.retainWhere((e) => e == 1);
        expect(set, {1});
      });

      test('check toList', () {
        final set = SetSignal({1, 2});
        expect(set.toList(growable: false), [1, 2]);
      });

      test('check cast', () {
        final set = SetSignal({1, 2});
        expect(set.cast<int>(), [1, 2]);
      });

      test('check toString', () {
        final set = SetSignal({1, 2});
        expect(set.toString(), startsWith('SetSignal<int>(value: {1, 2}'));
      });

      test('check contains', () {
        final set = SetSignal({1, 2});
        expect(set.contains(1), true);
        expect(set.contains(3), false);
      });

      test('check lookup', () {
        final set = SetSignal({1, 2});
        expect(set.lookup(1), 1);
        expect(set.lookup(3), null);
      });

      test('check retainAll', () {
        final set = SetSignal({1, 2, 3, 4});
        expect(set, {1, 2, 3, 4});
        set.retainAll({1, 3, 10});
        expect(set, {1, 3});
      });

      test('check set', () {
        final set = SetSignal({1, 2});
        expect(set, {1, 2});
        set.set({3, 4});
        expect(set, {3, 4});
      });

      test('check set with equals', () {
        final set =
            SetSignal<int>({1, 2}, options: const SignalOptions(equals: true));
        expect(set, {1, 2});
        set.set({3, 4});
        expect(set, {3, 4});
      });

      test('check updateValue', () {
        final set = SetSignal({1, 2});
        expect(set, {1, 2});
        set.updateValue((v) => v..add(3));
        expect(set, {1, 2, 3});
      });
    },
    timeout: const Timeout(Duration(seconds: 1)),
  );

  group(
    'MapSignal tests',
    () {
      test('check [] operator', () {
        final map = MapSignal({'a': 1, 'b': 2});
        expect(map['a'], 1);
        expect(map['c'], null);
        expect(map['b'], 2);
      });

      test('check []= operator', () {
        final map = MapSignal({'a': 1, 'b': 2});
        expect(map['a'], 1);
        map['a'] = 3;
        expect(map['a'], 3);
      });

      test('check clear', () {
        final map = MapSignal({'a': 1, 'b': 2});
        expect(map, {'a': 1, 'b': 2});
        map.clear();
        expect(map, isEmpty);
      });

      test('check keys', () {
        final map = MapSignal({'a': 1, 'b': 2});
        expect(map.keys, ['a', 'b']);
        map.clear();
        expect(map.keys, isEmpty);
      });

      test('check values', () {
        final map = MapSignal({'a': 1, 'b': 2});
        expect(map.values, [1, 2]);
        map.clear();
        expect(map.values, isEmpty);
      });

      test('check remove', () {
        final map = MapSignal({'a': 1, 'b': 2});
        expect(map, {'a': 1, 'b': 2});
        map.remove('a');
        expect(map, {'b': 2});
      });

      test('check cast', () {
        final map = MapSignal({'a': 1, 'b': 2});
        expect(map.cast<String, int>(), {'a': 1, 'b': 2});
      });

      test('check length', () {
        final map = MapSignal({'a': 1, 'b': 2});
        expect(map.length, 2);
        map['c'] = 3;
        expect(map.length, 3);
      });

      test('check isEmpty', () {
        final map = MapSignal({'a': 1, 'b': 2});
        expect(map.isEmpty, false);
        map.clear();
        expect(map.isEmpty, true);
      });

      test('check isNotEmpty', () {
        final map = MapSignal({'a': 1, 'b': 2});
        expect(map.isNotEmpty, true);
        map.clear();
        expect(map.isNotEmpty, false);
      });

      test('check containsKey', () {
        final map = MapSignal({'a': 1, 'b': 2});
        expect(map.containsKey('a'), true);
        expect(map.containsKey('c'), false);
      });

      test('check containsValue', () {
        final map = MapSignal({'a': 1, 'b': 2});
        expect(map.containsValue(1), true);
        expect(map.containsValue(3), false);
      });

      test('check entries', () {
        final map = MapSignal({'a': 1, 'b': 2});
        expect(Map.fromEntries(map.entries), map);
        map.clear();
        expect(map.entries, isEmpty);
      });

      test('check addEntries', () {
        final map = MapSignal({'a': 1, 'b': 2});
        expect(map, {'a': 1, 'b': 2});
        map.addEntries({'c': 3, 'd': 4}.entries);
        expect(map, {'a': 1, 'b': 2, 'c': 3, 'd': 4});
      });

      test('check addAll', () {
        final map = MapSignal({'a': 1, 'b': 2});
        expect(map, {'a': 1, 'b': 2});
        map.addAll({'c': 3, 'd': 4});
        expect(map, {'a': 1, 'b': 2, 'c': 3, 'd': 4});
      });

      test('check putIfAbset', () {
        final map = MapSignal({'a': 1, 'b': 2});
        expect(map, {'a': 1, 'b': 2});
        map.putIfAbsent('c', () => 3);
        expect(map, {'a': 1, 'b': 2, 'c': 3});
        map.putIfAbsent('a', () => 4);
        expect(map, {'a': 1, 'b': 2, 'c': 3});
      });

      test('check removeWhere', () {
        final map = MapSignal({'a': 1, 'b': 2, 'c': 1});
        expect(map, {'a': 1, 'b': 2, 'c': 1});
        map.removeWhere((k, v) => v == 1);
        expect(map, {'b': 2});
      });

      test('check update', () {
        final map = MapSignal({'a': 1, 'b': 2});
        expect(map, {'a': 1, 'b': 2});
        map.update('a', (value) => 3);
        expect(map, {'a': 3, 'b': 2});

        map.update('c', (value) => 4, ifAbsent: () => 4);
        expect(map, {'a': 3, 'b': 2, 'c': 4});

        expect(() => map.update('d', (value) => 5), throwsArgumentError);
      });

      test('check updateAll', () {
        final map = MapSignal({'a': 1, 'b': 2});
        expect(map, {'a': 1, 'b': 2});
        map.updateAll((k, v) => v * 2);
        expect(map, {'a': 2, 'b': 4});
      });

      test('check toString', () {
        final map = MapSignal({'a': 1, 'b': 2});
        expect(
          map.toString(),
          startsWith('MapSignal<String, int>(value: {a: 1, b: 2}'),
        );
      });

      test('check set', () {
        final map = MapSignal({'a': 1, 'b': 2});
        expect(map, {'a': 1, 'b': 2});
        map.set({'c': 3, 'd': 4});
        expect(map, {'c': 3, 'd': 4});
      });

      test('check set with equals', () {
        final map = MapSignal<String, int>(
          {'a': 1, 'b': 2},
          options: const SignalOptions(equals: true),
        );
        expect(map, {'a': 1, 'b': 2});
        map.set({'c': 3, 'd': 4});
        expect(map, {'c': 3, 'd': 4});
      });

      test('check updateValue', () {
        final map = MapSignal({'a': 1, 'b': 2});
        expect(map, {'a': 1, 'b': 2});
        map.updateValue((v) {
          v['c'] = 3;
          return v;
        });
        expect(map, {'a': 1, 'b': 2, 'c': 3});
      });
    },
    timeout: const Timeout(Duration(seconds: 1)),
  );
}

class _AlwaysZeroRandom implements Random {
  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;

  @override
  int nextInt(int max) => 0;
}
