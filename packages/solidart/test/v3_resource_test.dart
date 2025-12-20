import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:solidart/v3.dart';
import 'package:test/test.dart';

void main() {
  group('fetcher resources', () {
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

      resource.state;
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

    test('fetcher error transitions to error then recovers on refresh', () async {
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
    });

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

        source.value = 1;
        source.value = 2;

        async.elapse(const Duration(milliseconds: 49));
        async.flushMicrotasks();

        expect(calls, 1);

        async.elapse(const Duration(milliseconds: 1));
        async.flushMicrotasks();

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
      resource.state;

      expect(resource.untrackedPreviousState?.isLoading, isTrue);

      await resource.refresh();

      expect(resource.untrackedPreviousState?.isLoading, isTrue);

      resource.state;

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

        async.elapse(const Duration(milliseconds: 50));
        async.flushMicrotasks();

        expect(calls, 1);
      });
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
}
