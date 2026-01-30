import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:solidart/solidart.dart';
import 'package:test/test.dart';

void main() {
  group('until', () {
    test('returns current value when condition already true', () async {
      final signal = Signal(0);

      final result = signal.until((value) => value == 0);

      expect(await Future.value(result), 0);
    });

    test('completes when condition becomes true', () async {
      final signal = Signal(0);

      final future = Future.value(signal.until((value) => value == 2));
      signal.value = 2;

      expect(await future, 2);
    });

    test('completes with TimeoutException when timed out', () {
      fakeAsync((async) {
        final signal = Signal(0);

        final future = Future.value(
          signal.until(
            (value) => value == 1,
            timeout: const Duration(seconds: 1),
          ),
        );

        var completed = false;
        expectLater(
          future,
          throwsA(isA<TimeoutException>()),
        ).whenComplete(() => completed = true);

        async
          ..elapse(const Duration(seconds: 1))
          ..flushMicrotasks();

        expect(completed, isTrue);
      });
    });
  });
}
