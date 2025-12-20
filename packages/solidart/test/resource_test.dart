import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:solidart/solidart.dart';
import 'package:test/test.dart';

void main() {
  group('fetcher resources', () {
    test('coalesces concurrent resolve calls', () async {
      final completer = Completer<int>();
      var calls = 0;
      final resource = Resource(() {
        calls++;
        return completer.future;
      });

      final first = resource.resolve();
      final second = resource.resolve();

      expect(calls, 1);

      completer.complete(10);
      await Future.wait([first, second]);

      expect(resource.state.asReady?.value, 10);
      expect(calls, 1);
    });

    test('refresh before resolve triggers a single fetch', () async {
      final completer = Completer<int>();
      var calls = 0;
      final resource = Resource(() {
        calls++;
        return completer.future;
      });

      final refreshFuture = resource.refresh();
      expect(calls, 1);

      completer.complete(5);
      await refreshFuture;

      expect(resource.state.asReady?.value, 5);
      expect(calls, 1);
    });

    test('lazy resource resolves on first read', () async {
      var calls = 0;
      final resource = Resource(() async {
        calls++;
        return 1;
      });

      expect(calls, 0);

      final state = resource.state;
      expect(state.isLoading, isTrue);

      await Future<void>.delayed(Duration.zero);

      expect(calls, 1);
      expect(resource.state.asReady?.value, 1);
    });

    test('refresh marks ready state as refreshing when enabled', () async {
      var value = 0;
      final resource = Resource(
        () async => ++value,
        useRefreshing: true,
        lazy: false,
      );

      await resource.resolve();

      expect(resource.state.asReady?.isRefreshing, isFalse);

      final refreshFuture = resource.refresh();

      expect(resource.state.asReady?.isRefreshing, isTrue);

      await refreshFuture;

      expect(resource.state.asReady?.value, 2);
      expect(resource.state.asReady?.isRefreshing, isFalse);
    });

    test('refresh goes to loading when useRefreshing is false', () async {
      final completer1 = Completer<int>();
      final completer2 = Completer<int>();
      var calls = 0;

      final resource = Resource(
        () {
          calls++;
          return calls == 1 ? completer1.future : completer2.future;
        },
        useRefreshing: false,
        lazy: false,
      );

      await Future<void>.delayed(Duration.zero);
      completer1.complete(1);
      await Future<void>.delayed(Duration.zero);

      expect(resource.state.asReady?.value, 1);

      final refreshFuture = resource.refresh();

      expect(resource.state.isLoading, isTrue);

      completer2.complete(2);
      await refreshFuture;

      expect(resource.state.asReady?.value, 2);
    });

    test('refresh uses latest response when requests overlap', () async {
      final completer1 = Completer<int>();
      final completer2 = Completer<int>();
      var calls = 0;

      final resource = Resource(
        () {
          calls++;
          return calls == 1 ? completer1.future : completer2.future;
        },
      );

      final _ = resource.state;
      await Future<void>.delayed(Duration.zero);
      expect(calls, 1);

      final refreshFuture = resource.refresh();
      expect(calls, 2);

      completer2.complete(2);
      await refreshFuture;
      expect(resource.state.asReady?.value, 2);

      completer1.complete(1);
      await Future<void>.delayed(Duration.zero);

      expect(resource.state.asReady?.value, 2);
    });

    test(
      'fetcher error transitions to error then recovers on refresh',
      () async {
        var shouldThrow = true;

        final resource = Resource(
          () async {
            if (shouldThrow) {
              throw StateError('boom');
            }
            return 42;
          },
          lazy: false,
        );

        await resource.resolve();

        expect(resource.state.hasError, isTrue);

        shouldThrow = false;
        await resource.refresh();

        expect(resource.state.asReady?.value, 42);
      },
    );

    test('source change triggers a single refresh', () async {
      final source = Signal(0);
      var calls = 0;

      final resource = Resource(
        () async {
          calls++;
          return source.value;
        },
        source: source,
        lazy: false,
      );

      await Future<void>.delayed(Duration.zero);
      expect(calls, 1);

      source.value = 1;
      await Future<void>.delayed(Duration.zero);

      expect(calls, 2);

      await Future<void>.delayed(Duration.zero);

      expect(calls, 2);

      resource.dispose();
    });

    test('debounce groups source-triggered refreshes', () {
      fakeAsync((async) {
        final source = Signal(0);
        var calls = 0;

        final resource = Resource(
          () async {
            calls++;
            return source.value;
          },
          source: source,
          debounceDelay: const Duration(milliseconds: 50),
          lazy: false,
        );

        async.flushMicrotasks();

        expect(calls, 1);

        source
          ..value = 1
          ..value = 2;

        async
          ..elapse(const Duration(milliseconds: 49))
          ..flushMicrotasks();

        expect(calls, 1);

        async
          ..elapse(const Duration(milliseconds: 1))
          ..flushMicrotasks();

        expect(calls, 2);

        resource.dispose();
      });
    });

    test('previousState updates after read', () async {
      var value = 0;
      final resource = Resource(
        () async => ++value,
        lazy: false,
      );

      await resource.resolve();
      {
        final _ = resource.state;
      }

      expect(resource.untrackedPreviousState?.isLoading, isTrue);

      await resource.refresh();

      expect(resource.untrackedPreviousState?.isLoading, isTrue);

      {
        final _ = resource.state;
      }

      expect(resource.untrackedPreviousState?.asReady?.value, 1);
    });

    test('dispose cancels debounce and prevents refresh', () {
      fakeAsync((async) {
        final source = Signal(0);
        var calls = 0;

        final resource = Resource(
          () async {
            calls++;
            return source.value;
          },
          source: source,
          debounceDelay: const Duration(milliseconds: 50),
          lazy: false,
        );

        async.flushMicrotasks();
        expect(calls, 1);

        source.value = 1;
        resource.dispose();

        async
          ..elapse(const Duration(milliseconds: 50))
          ..flushMicrotasks();

        expect(calls, 1);
      });
    });

    test('dispose ignores in-flight fetch result', () async {
      final completer = Completer<int>();
      var calls = 0;
      final resource = Resource(() {
        calls++;
        return completer.future;
      });

      final resolveFuture = resource.resolve();
      expect(calls, 1);

      resource.dispose();

      completer.complete(42);
      await resolveFuture;
      await Future<void>.delayed(Duration.zero);

      expect(resource.untrackedState.isLoading, isTrue);
    });
  });

  group('stream resources', () {
    test('refresh cancels and resubscribes', () async {
      var listenCount = 0;
      var cancelCount = 0;
      final controller = StreamController<int>.broadcast(
        onListen: () => listenCount++,
        onCancel: () => cancelCount++,
      );

      final resource = Resource.stream(
        () => controller.stream,
        lazy: false,
      );

      await Future<void>.delayed(Duration.zero);
      expect(listenCount, 1);

      controller.add(1);
      await Future<void>.delayed(Duration.zero);
      expect(resource.state.asReady?.value, 1);

      await resource.refresh();
      await Future<void>.delayed(Duration.zero);
      expect(cancelCount, 1);
      expect(listenCount, 2);

      controller.add(2);
      await Future<void>.delayed(Duration.zero);
      expect(resource.state.asReady?.value, 2);

      await controller.close();
      resource.dispose();
    });

    test('refresh ignores events from previous stream', () async {
      final controller1 = StreamController<int>();
      final controller2 = StreamController<int>();
      var index = 0;
      final streams = [controller1.stream, controller2.stream];

      final resource = Resource.stream(
        () => streams[index++],
        lazy: false,
      );

      await Future<void>.delayed(Duration.zero);
      controller1.add(1);
      await Future<void>.delayed(Duration.zero);
      expect(resource.state.asReady?.value, 1);

      await resource.refresh();
      await Future<void>.delayed(Duration.zero);

      controller1.add(99);
      await Future<void>.delayed(Duration.zero);
      expect(resource.state.asReady?.value, 1);

      controller2.add(2);
      await Future<void>.delayed(Duration.zero);
      expect(resource.state.asReady?.value, 2);

      await controller1.close();
      await controller2.close();
      resource.dispose();
    });

    test('stream errors update state', () async {
      final controller = StreamController<int>();
      final resource = Resource.stream(
        () => controller.stream,
        lazy: false,
      );

      await Future<void>.delayed(Duration.zero);

      controller.addError(StateError('boom'), StackTrace.current);
      await Future<void>.delayed(Duration.zero);

      expect(resource.state.hasError, isTrue);

      await controller.close();
      resource.dispose();
    });

    test('dispose stops stream updates', () async {
      final controller = StreamController<int>();
      final resource = Resource.stream(
        () => controller.stream,
        lazy: false,
      );

      await Future<void>.delayed(Duration.zero);
      expect(controller.hasListener, isTrue);

      resource.dispose();

      expect(controller.hasListener, isFalse);

      await controller.close();
    });
  });

  group('resource state extensions', () {
    test('flags and accessors for ready/loading/error', () {
      const ready = ResourceState<int>.ready(1, isRefreshing: true);
      const loading = ResourceState<int>.loading();
      final error = ResourceState<int>.error(
        StateError('boom'),
        stackTrace: StackTrace.current,
        isRefreshing: true,
      );

      expect(ready.isReady, isTrue);
      expect(ready.isLoading, isFalse);
      expect(ready.hasError, isFalse);
      expect(ready.isRefreshing, isTrue);
      expect(ready.asReady?.value, 1);
      expect(ready.asError, isNull);
      expect(ready.value, 1);
      expect(ready.error, isNull);

      expect(loading.isLoading, isTrue);
      expect(loading.isReady, isFalse);
      expect(loading.hasError, isFalse);
      expect(loading.isRefreshing, isFalse);
      expect(loading.asReady, isNull);
      expect(loading.asError, isNull);
      expect(loading.value, isNull);
      expect(loading.error, isNull);

      expect(error.hasError, isTrue);
      expect(error.isReady, isFalse);
      expect(error.isLoading, isFalse);
      expect(error.isRefreshing, isTrue);
      expect(error.asReady, isNull);
      expect(error.asError?.error, isA<StateError>());
      expect(error.error, isA<StateError>());
      expect(() => error.value, throwsA(isA<StateError>()));
    });

    test('when/maybeWhen/maybeMap behave as expected', () {
      const ready = ResourceState<int>.ready(2);
      final error = ResourceState<int>.error(StateError('boom'));
      const loading = ResourceState<int>.loading();

      expect(
        ready.when(
          ready: (value) => 'ready $value',
          error: (_, stackTrace) => 'error',
          loading: () => 'loading',
        ),
        'ready 2',
      );

      expect(
        error.when(
          ready: (_) => 'ready',
          error: (err, stackTrace) => err.toString(),
          loading: () => 'loading',
        ),
        'Bad state: boom',
      );

      expect(
        loading.when(
          ready: (_) => 'ready',
          error: (_, stackTrace) => 'error',
          loading: () => 'loading',
        ),
        'loading',
      );

      expect(
        ready.maybeWhen(orElse: () => 'fallback'),
        'fallback',
      );

      expect(
        error.maybeWhen(
          orElse: () => 'fallback',
          error: (err, stackTrace) => err.runtimeType.toString(),
        ),
        'StateError',
      );

      expect(
        loading.maybeMap(
          orElse: () => 'fallback',
          loading: (_) => 'loading',
        ),
        'loading',
      );
    });
  });
}
