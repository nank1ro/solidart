// ignore_for_file: cascade_invocations

import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:mockito/mockito.dart';
import 'package:solidart/solidart.dart';
import 'package:solidart/src/signal.dart';
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

class MockSolidartObserver extends Mock implements SolidartObserver {}

void main() {
  group(
    'Signal tests - ',
    () {
      test('with equals true it notifies only when the value changes',
          () async {
        final counter = Signal(0);

        final cb = MockCallbackFunction();
        final unobserve = counter.observe((_, __) => cb());

        expect(counter(), 0);

        counter.value = 1;
        await pumpEventQueue();
        expect(counter.value, 1);

        counter.value = 2;
        counter.value = 2;
        counter.value = 2;

        await pumpEventQueue();
        counter.value = 3;

        expect(counter.value, 3);
        await pumpEventQueue();
        verify(cb()).called(3);
        // clear
        unobserve();
      });

      test(
          'with the identical comparator it notifies only when the comparator '
          'returns false', () async {
        final signal = Signal<_A?>(null);
        final cb = MockCallbackFunction();
        final unobserve = signal.observe((_, __) => cb());

        expect(signal.value, null);
        final a = _A();

        signal.value = a;
        signal.value = a;
        signal.value = a;

        await pumpEventQueue();

        signal.value = _A();
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

      test('test until()', () async {
        final count = Signal(0);

        unawaited(
          expectLater(count.until((value) => value > 5), completion(11)),
        );
        count.value = 2;
        count.value = 11;
      });

      test('test until() with timeout - condition met before timeout',
          () async {
        final count = Signal(0);

        unawaited(
          expectLater(
            count.until(
              (value) => value > 5,
              timeout: const Duration(milliseconds: 500),
            ),
            completion(11),
          ),
        );
        // Wait a bit then update the value before timeout
        await Future<void>.delayed(const Duration(milliseconds: 100));
        count.value = 11;
      });

      test('test until() with timeout - timeout occurs before condition',
          () async {
        final count = Signal(0);

        unawaited(
          expectLater(
            count.until(
              (value) => value > 5,
              timeout: const Duration(milliseconds: 100),
            ),
            throwsA(isA<TimeoutException>()),
          ),
        );

        // Don't update the value, let it timeout
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });

      test(
          '''test until() with timeout - condition already met returns immediately''',
          () async {
        final count = Signal(10); // Value already meets condition

        final result = await count.until(
          (value) => value > 5,
          timeout: const Duration(milliseconds: 100),
        );

        expect(result, 10);
      });

      test('test until() with timeout - proper cleanup on timeout', () async {
        final count = Signal(0);

        // Create an until that will timeout
        unawaited(
          Future.value(
            count.until(
              (value) => value > 5,
              timeout: const Duration(milliseconds: 50),
            ),
          ).catchError((_) {
            // Expected to timeout, return a dummy value
            return 0;
          }),
        );

        // Wait for timeout to occur
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Now update the value - if cleanup worked properly,
        // no additional effects should trigger
        count.value = 10;

        // Give time for any potential side effects
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // If we reach here without issues, cleanup worked
        // Why is 10? The signal is destroyed, There should be no more data
        // updates
        expect(count.value, 0);
      });

      test('test until() with timeout - proper cleanup on success', () async {
        final count = Signal(0);

        final future = count.until(
          (value) => value > 5,
          timeout: const Duration(milliseconds: 200),
        );

        // Update value to meet condition
        count.value = 10;

        // Wait for completion
        final result = await future;
        expect(result, 10);

        // Give time for cleanup
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Additional changes shouldn't affect anything since effect was
        // disposed
        count.value = 15;

        // If we reach here without issues, cleanup worked
        // Why is 10? The signal is destroyed, There should be no more data
        // updates
        expect(count.value, 10);
      });

      test('check toString()', () {
        final s = Signal(0);
        expect(s.toString(), startsWith('Signal<int>(value: 0'));
      });

      test('check custom name', () {
        final s = ReadableSignal(0, name: 'custom-name');
        expect(s.name, 'custom-name');
      });

      test('check custom name when lazy', () {
        final s = ReadableSignal<int>.lazy(name: 'lazy-custom-name');
        expect(s.name, 'lazy-custom-name');
      });

      test('check Signal becomes ReadSignal', () {
        final s = Signal(0);
        expect(s, const TypeMatcher<Signal<int>>());
        expect(s.toReadSignal(), const TypeMatcher<ReadonlySignal<int>>());
      });

      test('Signal is disposed after dispose', () {
        final s = Signal(0);
        expect(s.disposed, false);
        s.dispose();
        expect(s.disposed, true);
      });

      test('Signal<bool> toggle', () {
        final signal = Signal(false);
        expect(signal.value, false);
        signal.toggle();
        expect(signal.value, true);
      });

      test('lazy Signal', () {
        final signal = Signal<bool>.lazy();
        expect(signal.hasValue, false);
        signal.value = true;
        expect(signal.hasValue, true);
      });

      test(
          '''lazy Signal trows StateError when accessing value before setting one''',
          () {
        final signal = Signal<bool>.lazy();
        expect(() => signal.value, throwsStateError);
      });

      test('untrackedValue', () {
        final counter = Signal(0);

        final cb = MockCallbackFunction();
        final unobserve = Effect(
          () {
            counter.untrackedValue;
            counter.untrackedPreviousValue;
            cb();
          },
          onError: (error) {
            //ignore
          },
        );
        addTearDown(unobserve.dispose);

        counter.value = 1;

        // An effect is always triggered once
        verify(cb()).called(1);
      });

      test('Test untracked', () {
        final count = Signal(0);
        final effectCount = Signal(0);
        int fn() => effectCount.value + 1;

        final cb = MockCallbackFunction();
        Effect(() {
          count.value;
          cb.call();

          // Whenever this effect is triggered, run `fn` that gives new value
          effectCount.value = untracked(fn);
        });

        expect(count.value, 0);
        expect(effectCount.value, 1);

        count.value = 1;
        expect(effectCount.value, 2);

        verify(cb()).called(2);
      });

      test("Check signal disposed isn't tracked by Computed", () {
        final count = Signal(1);
        final doubleCount = Computed(() => count.value * 2);

        expect(doubleCount.value, 2);
        expect(count.disposed, false);

        count.dispose();
        expect(count.disposed, true);
        expect(doubleCount.disposed, true);

        count.value = 2;
        expect(doubleCount.value, 2);
      });

      test('Check Signal autoDisposes if no longer used', () {
        final count = Signal(0, autoDispose: true);
        final effect = Effect(() => count.value);

        expect(count.disposed, false);
        expect(effect.disposed, false);

        effect.dispose();
        expect(effect.disposed, true);
        expect(count.disposed, true);
      });

      test('Check Signal do not autoDisposes if no longer used', () {
        final count = Signal(0, autoDispose: false);
        final effect = Effect(() => count.value);

        expect(count.disposed, false);
        expect(effect.disposed, false);

        effect.dispose();
        expect(effect.disposed, true);
        expect(count.disposed, false);

        count.value = 1;
        expect(count.value, 1);
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
        Effect(() => cb(signal1.value));
        Effect(() => cb(signal2.value));

        signal1.value = 1;
        await pumpEventQueue();
        verify(cb(1)).called(1);
        signal1.value = 2;
        await pumpEventQueue();
        verify(cb(2)).called(1);
        signal2.value = 4;
        signal1.value = 4;
        await pumpEventQueue();
        verify(cb(4)).called(2);
      });

      test('check effect reaction with delay', () async {
        final cb = MockCallbackFunction();
        final disposeEffect = Effect(
          cb,
          delay: const Duration(milliseconds: 500),
          autoDispose: false,
          onError: (error) {
            // ignore
          },
        );
        addTearDown(disposeEffect.dispose);
        verifyNever(cb());
        await Future<void>.delayed(const Duration(milliseconds: 501));
        verify(cb()).called(1);
      });

      test('check effect onError', () async {
        Object? detectedError;
        Effect(
          () => throw Exception(),
          onError: (error) {
            detectedError = error;
          },
        );
        expect(detectedError, isA<Exception>());
      });
    },
    timeout: const Timeout(Duration(seconds: 1)),
  );

  group(
    'Computed tests - ',
    () {
      test('check that a Computed updates only for the selected value',
          () async {
        final klass = _B(_C(0));
        final s = Signal(klass);
        final selected = Computed(() => s.value.c.count);
        final cb = MockCallbackFunctionWithValue<int>();

        // A computed always has a value
        expect(selected.hasValue, true);

        void listener() {
          cb(selected.value);
        }

        final unobserve = selected.observe((_, __) => listener());

        s.value = _B(_C(1));
        await pumpEventQueue();

        s.value = _B(_C(5));
        await pumpEventQueue();

        s.value = _B(_C(1));
        await pumpEventQueue();

        verify(cb(1)).called(2);
        s.value = _B(_C(2));
        await pumpEventQueue();
        s.value = _B(_C(2));
        await pumpEventQueue();
        s.value = _B(_C(3));
        await pumpEventQueue();
        verify(cb(2)).called(1);
        verify(cb(3)).called(1);

        // clear
        unobserve();
      });

      test('Computed contains previous value', () async {
        final signal = Signal(0);
        final derived = Computed(() => signal.value * 2);
        await pumpEventQueue();
        expect(derived.hasPreviousValue, false);
        expect(derived.previousValue, null);

        signal.value = 1;
        await pumpEventQueue();
        expect(derived.hasPreviousValue, true);
        expect(derived.previousValue, 0);

        signal.value = 2;
        await pumpEventQueue();
        expect(derived.hasPreviousValue, true);
        expect(derived.previousValue, 2);

        signal.value = 1;
        await pumpEventQueue();
        expect(derived.hasPreviousValue, true);
        expect(derived.previousValue, 4);
      });

      test('signal has previous value', () {
        final s = Signal(0);
        expect(s.hasPreviousValue, false);
        s.value = 1;
        expect(s.hasPreviousValue, true);
      });

      test('nullable derived signal', () async {
        final count = Signal<int?>(0);
        final doubleCount = Computed(() {
          if (count.value == null) return null;
          return count.value! * 2;
        });

        await pumpEventQueue();
        expect(doubleCount.value, 0);

        count.value = 1;
        await pumpEventQueue();
        expect(doubleCount.value, 2);

        count.value = null;
        await pumpEventQueue();
        expect(doubleCount.value, null);
      });

      test('derived signal disposes', () async {
        final count = Signal(0);
        final doubleCount = Computed(() => count.value * 2);
        expect(doubleCount.disposed, false);
        doubleCount.dispose();
        expect(doubleCount.disposed, true);
      });

      test('check derived signal that throws', () async {
        final count = Signal(1);
        final doubleCount = Computed(
          () {
            if (count.value == 1) {
              return count.value * 2;
            }
            return throw Exception();
          },
        );

        count.value = 3;
        expect(
          () => doubleCount.value,
          throwsA(const TypeMatcher<Exception>()),
        );
      });

      test('check toString computed', () {
        final count = Signal(1);
        final doubleCount = Computed(() => count.value * 2);

        expect(doubleCount.toString(), startsWith('Computed<int>(value: 2'));
      });

      test("check disposed Computed won't react", () {
        final count = Signal(0);
        final doubleCount = Computed(() => count.value * 2);
        var onDisposeCalled = false;
        doubleCount.onDispose(() {
          onDisposeCalled = true;
        });
        final cb = MockCallbackFunctionWithValue<int>();
        doubleCount.observe((_, __) {
          cb(doubleCount.value);
        });

        expect(doubleCount.disposed, false);
        expect(onDisposeCalled, false);

        count.value = 1;
        expect(doubleCount.value, 2);
        verify(cb(2)).called(1);

        doubleCount.dispose();
        expect(doubleCount.disposed, true);
        expect(onDisposeCalled, true);

        count.value = 2;
        expect(doubleCount(), 2);
        verifyNever(cb(2));
      });

      test('Check Computed runs manually by counting the number of runs',
          () async {
        final cb = MockCallbackFunction();
        final count = Signal(0);
        final doubleCount = Computed(() {
          cb();
          return count.value * 2;
        });
        // trigger reactive value
        doubleCount.value;
        // run manually twice
        doubleCount.run();
        doubleCount.run();
        // 3 times in total, 1 automatically and 2 manually
        verify(cb()).called(3);
      });

      test('Check Computed autoDisposes if no longer used', () {
        final count = Signal(0);
        final doubleCount = Computed(() => count.value * 2, autoDispose: true);

        expect(count.disposed, false);
        expect(doubleCount.disposed, false);

        count.value = 1;
        expect(count.value, 1);
        expect(doubleCount.value, 2);

        count.dispose();
        expect(count.disposed, true);
        // After disposing, the Computed should be disposed
        expect(doubleCount.disposed, true);

        // Changing the source signal should not trigger the Computed anymore
        count.value = 2;
        expect(doubleCount.value, 2);
      });

      test('Check Computed do not autoDisposes if no longer used', () {
        final count = Signal(0);
        final doubleCount = Computed(() => count.value * 2, autoDispose: false);

        expect(count.disposed, false);
        expect(doubleCount.disposed, false);

        count.value = 1;
        expect(count.value, 1);
        expect(doubleCount.value, 2);

        count.dispose();
        expect(count.disposed, true);
        // After disposing, the Computed should NOT be disposed
        expect(doubleCount.disposed, false);

        // Changing the source signal should not trigger the Computed anymore
        // because the count signal is disposed
        count.value = 2;
        expect(doubleCount.value, 2);
      });
    },
    timeout: const Timeout(Duration(seconds: 1)),
  );

  group(
    'ReadSignal tests',
    () {
      // test('check ReadSignal value and listener count', () {
      //   final s = ReadSignal(0);
      //   expect(s.value, 0);
      //   expect(s.previousValue, null);
      //   expect(s.listenerCount, 0);
      //
      //   Effect((_) {
      //     s();
      //   });
      //   expect(s.listenerCount, 1);
      // });

      test('check toString()', () {
        final s = ReadableSignal(0);
        expect(s.toString(), startsWith('Signal<int>(value: 0'));
      });

      test('check untrackedValue throws if no value', () {
        final count = Signal<int>.lazy();
        expect(() => count.untrackedValue, throwsStateError);
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

        final resource = Resource.stream(() => streamController.stream);
        expect(resource.state, isA<ResourceLoading<int>>());
        expect(resource.untrackedState, isA<ResourceLoading<int>>());
        expect(resource.previousState, isNull);
        expect(resource.untrackedPreviousState, isNull);
        streamController.add(1);
        await pumpEventQueue();
        expect(resource.state, isA<ResourceReady<int>>());
        expect(resource.untrackedState, isA<ResourceReady<int>>());
        expect(resource.previousState, isA<ResourceLoading<int>>());
        expect(resource.untrackedPreviousState, isA<ResourceLoading<int>>());
        expect(resource.state.value, 1);
        expect(resource.untrackedState.value, 1);

        streamController.add(10);
        await pumpEventQueue();
        expect(resource(), isA<ResourceReady<int>>());
        expect(
          resource.previousState,
          isA<ResourceReady<int>>().having(
            (p0) => p0.value,
            'previousState value',
            1,
          ),
        );
        expect(resource.state.value, 10);

        streamController.addError(UnimplementedError());
        await pumpEventQueue();
        expect(resource.state, isA<ResourceError<int>>());
        expect(resource.state.error, isUnimplementedError);
      });

      test('check Resource with stream and source', () async {
        final count = Signal(-1);

        final resource = Resource.stream(
          () {
            if (count.value < 1) return Stream.value(0);
            return Stream.value(count.value);
          },
          source: count,
          lazy: false,
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

        count.value = 5;
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

        final resource = Resource.stream(
          () {
            if (source.value.isEven) {
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
        source.value = 1;
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
        source.value = 2;
        await pumpEventQueue();
        expect(resource.state.value, 3);
      });

      test('check Resource with future that throws', () async {
        Future<User> getUser() => throw Exception();
        final resource = Resource<User>(
          getUser,
          lazy: false,
        );

        addTearDown(resource.dispose);

        await pumpEventQueue();
        expect(resource.state, isA<ResourceError<User>>());
        expect(resource.state.error, isException);
      });

      test('check Resource with future', () async {
        final userId = Signal(0);

        Future<User> getUser() {
          if (userId.value == 2) throw Exception();
          return Future.value(User(id: userId.value));
        }

        final resource = Resource(
          getUser,
          source: userId,
          lazy: false,
        );

        await pumpEventQueue();
        expect(resource.state, isA<ResourceReady<User>>());
        expect(resource.state.value, const User(id: 0));

        userId.value = 1;
        await pumpEventQueue();
        expect(resource.state, isA<ResourceReady<User>>());
        expect(resource.state.value, const User(id: 1));

        userId.value = 2;
        await pumpEventQueue();
        expect(resource.state, isA<ResourceError<User>>());
        expect(resource.state.error, isException);

        userId.value = 3;
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

      test('check Resource with useRefreshing false', () async {
        final userId = Signal(0);

        Future<User> getUser() {
          if (userId.value == 2) throw Exception();
          return Future.value(User(id: userId.value));
        }

        final resource = Resource(
          getUser,
          source: userId,
          useRefreshing: false,
          lazy: false,
        );

        addTearDown(resource.dispose);
        addTearDown(userId.dispose);

        await pumpEventQueue();
        expect(resource.state, isA<ResourceReady<User>>());
        expect(resource.state.value, const User(id: 0));

        userId.value = 1;
        expect(resource.state, isA<ResourceLoading<User>>());
      });

      test('update ResourceState', () async {
        Future<int> fetcher() => Future.value(1);
        final resource = Resource(fetcher);
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
        final resource = Resource(fetcher);
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
        final resource = Resource.stream(() => controller.stream);
        expect(resource.state, isA<ResourceLoading<int>>());

        await resource.refresh();
        expect(resource.state, isA<ResourceLoading<int>>());

        controller.add(1);
        await pumpEventQueue();
        expect(resource.state, isA<ResourceReady<int>>());
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
        var loadingCallbackCount = 0;
        var errorCalledTimes = 0;
        var refreshingOnDataTimes = 0;
        var refreshingOnErrorTimes = 0;
        final resource = Resource(fetcher);

        Effect(
          () {
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
                loadingCallbackCount++;
              },
            );
          },
        );

        await Future<void>.delayed(const Duration(milliseconds: 40));
        expect(loadingCallbackCount, 1);
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

        expect(loadingCallbackCount, 1);
      });

      test(
        'test untilReady()',
        () async {
          Future<int> fetcher() => Future.delayed(
                const Duration(milliseconds: 300),
                () => 1,
              );
          final count = Resource(fetcher);

          await expectLater(count.untilReady(), completion(1));
        },
      );

      test('until syncronously fires the then callback if condition is met',
          () async {
        final count = Resource<int>(() => Future.value(1), lazy: false);
        var fired = false;
        count.until((v) => true).then((value) {
          fired = true;
        });
        // Wait for microtask queue to process
        // ignore: inference_failure_on_instance_creation
        await Future.value();
        expect(fired, true);
      });

      test('until asynchronously fires the then callback if condition is met',
          () async {
        final count = Signal(0);
        var fired = false;
        count.until((v) => v == 1).then((value) => fired = true);
        count.value = 1;
        await pumpEventQueue();
        expect(fired, true);
      });

      test('check toString()', () async {
        final r = Resource(
          () => Future.value(1),
          lazy: false,
        );
        await pumpEventQueue();
        expect(
          r.toString(),
          startsWith(
            '''Resource<int>(state: ResourceReady<int>(value: 1, refreshing: false)''',
          ),
        );
      });

      test('check Resource debounceDelay for source that triggers very often',
          () async {
        final source = Signal(0);

        Future<int> fetcher() => Future.value(42);

        final resource = Resource(
          fetcher,
          source: source,
          debounceDelay: const Duration(milliseconds: 100),
          lazy: false, // Start immediately so we get an initial load
        );

        addTearDown(() {
          resource.dispose();
          source.dispose();
        });

        // Wait for initial load to complete
        await pumpEventQueue();
        expect(resource.state, isA<ResourceReady<int>>());

        // Rapidly change the source value multiple times
        for (var i = 1; i < 10; i++) {
          source.value = i;
          await Future<void>.delayed(const Duration(milliseconds: 30));
        }

        // Wait enough time to ensure the debounce delay has passed
        // and the Future completes
        await Future<void>.delayed(const Duration(milliseconds: 200));

        // At this point, the resource should still be ready after debounced
        // refresh
        expect(resource.state, isA<ResourceReady<int>>());
      });
    },
    timeout: const Timeout(Duration(seconds: 1)),
  );

  // group(
  //   'ReactiveContext tests',
  //   () {
  //     test('throws Exception for reactions that do not converge', () {
  //       var firstTime = true;
  //       final count = Signal(0);
  //       final d = Effect((_) {
  //         // watch count
  //         count.value;
  //         if (firstTime) {
  //           firstTime = false;
  //           return;
  //         }
  //
  //         // cyclic-dependency
  //         // this effect will keep on getting triggered as count.value keeps
  //         // changing every time it's invoked
  //         count.value++;
  //       });
  //
  //       expect(
  //         () => count.value = 1,
  //         throwsA(const TypeMatcher<SolidartReactionException>()),
  //       );
  //       d();
  //     });
  //   },
  //   timeout: const Timeout(Duration(seconds: 1)),
  // );

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
        list.value = [3, 4];
        expect(list, [3, 4]);
      });

      test('check set with equals', () {
        final list = ListSignal<int>([1, 2]);
        expect(list, [1, 2]);
        list.value = [3, 4];
        expect(list, [3, 4]);
      });

      test('check updateValue', () {
        final list = ListSignal([1, 2]);
        expect(list, [1, 2]);
        list.updateValue((v) => v..add(3));
        expect(list, [1, 2, 3]);
      });

      test('check value and previousValue', () {
        final list = ListSignal([1, 2]);
        expect(list, [1, 2]);
        expect(list.previousValue, null);
        list.updateValue((v) => v..add(3));
        expect(list, [1, 2, 3]);
        expect(list.previousValue, [1, 2]);
      });

      test('check equals', () {
        final list = ListSignal([1], equals: true);
        expect(list, [1]);
        list.value = [1, 2];
        expect(list, [1, 2]);
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
        set.value = {3, 4};
        expect(set, {3, 4});
      });

      test('check set with equals', () {
        final set = SetSignal<int>({1, 2});
        expect(set, {1, 2});
        set.value = {3, 4};
        expect(set, {3, 4});
      });

      test('check updateValue', () {
        final set = SetSignal({1, 2});
        expect(set, {1, 2});
        set.updateValue((v) => v..add(3));
        expect(set, {1, 2, 3});
      });

      test('check value and previousValue', () {
        final set = SetSignal({1, 2});
        expect(set, {1, 2});
        expect(set.previousValue, null);
        set.updateValue((v) => v..add(3));
        expect(set, {1, 2, 3});
        expect(set.previousValue, {1, 2});
      });

      test('check equals', () {
        final set = SetSignal({1}, equals: true);
        expect(set, {1});
        set.value = {1, 2};
        expect(set, {1, 2});
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
        map.value = {'c': 3, 'd': 4};
        expect(map, {'c': 3, 'd': 4});
      });

      test('check set with equals', () {
        final map = MapSignal<String, int>({'a': 1, 'b': 2});
        expect(map, {'a': 1, 'b': 2});
        map.value = {'c': 3, 'd': 4};
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

      test('check value and previousValue', () {
        final map = MapSignal({'a': 1, 'b': 2});
        expect(map, {'a': 1, 'b': 2});
        map.updateValue((v) {
          v['c'] = 3;
          return v;
        });
        expect(map, {'a': 1, 'b': 2, 'c': 3});
        expect(map.previousValue, {'a': 1, 'b': 2});
      });

      test('check equals', () {
        final map = MapSignal({'a': 1}, equals: true);
        expect(map, {'a': 1});
        map.value = {'b': 2};
        expect(map, {'b': 2});
      });
    },
    timeout: const Timeout(Duration(seconds: 1)),
  );

  group(
    'SolidartObserver',
    () {
      tearDown(SolidartConfig.observers.clear);

      test('didCreateSignal is fired on signal creation', () {
        final observer = MockSolidartObserver();
        SolidartConfig.observers.add(observer);
        final count = Signal(0);
        verify(observer.didCreateSignal(count)).called(1);
      });

      test('didUpdateSignal is fired on signal update', () {
        final observer = MockSolidartObserver();
        SolidartConfig.observers.add(observer);
        final count = Signal(0);
        verifyNever(observer.didUpdateSignal(count));
        count.value++;
        verify(observer.didUpdateSignal(count)).called(1);
      });

      test('didDisposeSignal is fired on signal update', () {
        final observer = MockSolidartObserver();
        SolidartConfig.observers.add(observer);
        final count = Signal(0);
        verifyNever(observer.didDisposeSignal(count));
        count.dispose();
        verify(observer.didDisposeSignal(count)).called(1);
      });

      test('modifications are batched', () {
        final x = Signal(10);
        final y = Signal(20);
        final total = Signal(30);

        final calls = <({int x, int y, int total})>[];
        expect(calls, isEmpty);
        expect(total.value, equals(30));

        final disposeEffect = Effect(() {
          calls.add((x: x.value, y: y.value, total: total.value));
        });

        addTearDown(disposeEffect.dispose);

        expect(
          calls,
          equals([
            (x: 10, y: 20, total: 30),
          ]),
        );

        batch(() {
          x.value++;
          y.value++;

          total.value = x.value + y.value;
        });

        expect(
          calls,
          equals([
            (x: 10, y: 20, total: 30),
            (x: 11, y: 21, total: 32),
          ]),
        );
      });

      test('should correctly propagate changes through computed signals', () {
        final source = Signal(0);
        final c1 = Computed(() => source.value % 2);
        final c2 = Computed(() => c1.value);
        final c3 = Computed(() => c2.value);

        c3.value;
        source.value = 1;
        c2.value;
        source.value = 3;

        expect(c3.value, equals(1));
      });
      test('should clear subscriptions when untracked by all subscribers', () {
        var bRunTimes = 0;

        final a = Signal(1);
        final b = Computed(() {
          bRunTimes++;
          return a.value * 2;
        });
        final disposeEffect = Effect(() => b.value);

        expect(bRunTimes, equals(1));

        a.value = 2;
        expect(bRunTimes, equals(2));

        disposeEffect();
        a.value = 2;
        expect(bRunTimes, equals(2));
      });

      test('should not run untracked inner effect', () {
        final a = Signal(3);
        final b = Computed(() => a.value > 0);

        late Effect disposeInnerEffect;

        final disposeEffect = Effect(
          () {
            if (b.value) {
              disposeInnerEffect = Effect(
                () {
                  if (a.value == 0) {
                    throw Error();
                  }
                },
                name: 'inner',
              );
            } else {
              disposeInnerEffect();
            }
          },
          name: 'outer',
        );

        addTearDown(() {
          a.dispose();
          b.dispose();
          disposeEffect();
          disposeInnerEffect();
        });

        a.value--;
        a.value--;
        a.value--;
        expect(b.value, isFalse);
      });

      test('should run outer effect first', () {
        final a = Signal(1);
        final b = Signal(1);

        late Effect disposeInnerEffect;
        final disposeEffect = Effect(() {
          if (a.value > 0) {
            disposeInnerEffect = Effect(() {
              b.value;
              if (a.value == 0) {
                throw Error();
              }
            });
          } else {
            disposeInnerEffect();
          }
        });

        addTearDown(() {
          disposeEffect();
          a.dispose();
          b.dispose();
        });

        batch(() {
          a.value = 0;
          b.value = 0;
        });
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
