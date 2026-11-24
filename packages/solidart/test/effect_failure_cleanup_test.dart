import 'dart:async';

import 'package:solidart/solidart.dart';
import 'package:test/test.dart';

/// Runs [body] in a zone that records the errors reported to it and the
/// timers created in it.
({List<Object> reported, List<Timer> timers}) _runInZone(void Function() body) {
  final reported = <Object>[];
  final timers = <Timer>[];
  runZonedGuarded(
    body,
    (error, _) => reported.add(error),
    zoneSpecification: ZoneSpecification(
      createTimer: (self, parent, zone, duration, callback) {
        final timer = parent.createTimer(zone, duration, callback);
        timers.add(timer);
        return timer;
      },
    ),
  );
  return (reported: reported, timers: timers);
}

String? _messageOf(Object? error) => (error as StateError?)?.message;

void main() {
  group('#197 a failed first run', () {
    test('does not run again before the error reaches the caller', () {
      final source = Signal(0);
      final trigger = Signal(false);
      final seen = <int>[];
      addTearDown(source.dispose);
      addTearDown(trigger.dispose);
      final writer = Effect(() {
        if (trigger.value) source.value = 1;
      });
      addTearDown(writer.dispose);

      Object? thrown;
      try {
        Effect(() {
          seen.add(source.value);
          if (source.untrackedValue == 0) {
            trigger.value = true;
            throw StateError('first');
          }
        });
      } catch (e) {
        thrown = e;
      }

      expect(_messageOf(thrown), 'first');
      expect(seen, [0]);
      expect(source.value, 1);
    });

    test('keeps its error when a queued effect also throws', () {
      final trigger = Signal(false);
      addTearDown(trigger.dispose);
      final queued = Effect(() {
        if (trigger.value) throw StateError('queued');
      });
      addTearDown(queued.dispose);

      Object? thrown;
      StackTrace? thrownStack;
      StackTrace? firstStack;
      final zone = _runInZone(() {
        try {
          Effect(() {
            trigger.value = true;
            try {
              throw StateError('first');
            } catch (_, st) {
              firstStack = st;
              rethrow;
            }
          });
        } catch (e, st) {
          thrown = e;
          thrownStack = st;
        }
      });

      expect(_messageOf(thrown), 'first');
      expect(thrownStack.toString(), firstStack.toString());
      expect(zone.reported.map(_messageOf), ['queued']);
    });
  });

  group('#198 a nested delayed effect', () {
    test('does not run after its parent fails and is disposed', () async {
      var seen = 0;
      try {
        Effect(() {
          Effect(() => seen++, delay: Duration.zero);
          throw StateError('parent');
        });
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(seen, 0);
    });

    test('does not run after its parent is disposed', () async {
      var seen = 0;
      late Effect child;
      late Effect parent;
      final zone = _runInZone(() {
        parent = Effect(() {
          child = Effect(
            () => seen++,
            delay: const Duration(milliseconds: 10),
          );
        });
      });
      addTearDown(child.dispose);

      parent.dispose();

      expect(child.disposed, isTrue);
      expect(zone.timers.single.isActive, isFalse);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(seen, 0);
    });

    test('dispose cancels the pending timer', () async {
      var seen = 0;
      late Effect effect;
      final zone = _runInZone(() {
        effect = Effect(
          () => seen++,
          delay: const Duration(milliseconds: 10),
        );
      });

      effect.dispose();

      expect(zone.timers.single.isActive, isFalse);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(seen, 0);
    });
  });

  group('#199 disposal with a throwing onDispose', () {
    test('an Effect disposes every dependency, then rethrows', () {
      final first = Signal(0, autoDispose: true)
        ..onDispose(() => throw StateError('cleanup'));
      final second = Signal(0, autoDispose: true);
      addTearDown(second.dispose);
      final effect = Effect(() {
        first.value;
        second.value;
      });

      Object? thrown;
      try {
        effect.dispose();
      } catch (e) {
        thrown = e;
      }

      expect(_messageOf(thrown), 'cleanup');
      expect((first.disposed, second.disposed), (true, true));
    });

    test('a Computed disposes every dependency, then rethrows', () {
      final first = Signal(0, autoDispose: true)
        ..onDispose(() => throw StateError('cleanup'));
      final second = Signal(0, autoDispose: true);
      addTearDown(second.dispose);
      final computed = Computed(
        () => first.value + second.value,
        autoDispose: true,
      );
      expect(computed.value, 0);

      Object? thrown;
      try {
        computed.dispose();
      } catch (e) {
        thrown = e;
      }

      expect(_messageOf(thrown), 'cleanup');
      expect(computed.disposed, isTrue);
      expect((first.disposed, second.disposed), (true, true));
    });

    test('rethrows the first error and reports later ones to the zone', () {
      final first = Signal(0, autoDispose: true)
        ..onDispose(() => throw StateError('first'));
      final second = Signal(0, autoDispose: true)
        ..onDispose(() => throw StateError('second'));
      final effect = Effect(() {
        first.value;
        second.value;
      });

      Object? thrown;
      final zone = _runInZone(() {
        try {
          effect.dispose();
        } catch (e) {
          thrown = e;
        }
      });

      expect(_messageOf(thrown), 'first');
      expect(zone.reported.map(_messageOf), ['second']);
      expect((first.disposed, second.disposed), (true, true));
    });

    test('a signal offers disposal to every subscriber, then rethrows', () {
      final source = Signal(0);
      final computed = Computed(() => source.value, autoDispose: true)
        ..onDispose(() => throw StateError('cleanup'));
      expect(computed.value, 0);
      final effect = Effect(() => source.value, autoDispose: true);

      Object? thrown;
      try {
        source.dispose();
      } catch (e) {
        thrown = e;
      }

      expect(_messageOf(thrown), 'cleanup');
      expect((computed.disposed, effect.disposed), (true, true));
    });

    test('a signal runs every onDispose callback, then rethrows', () {
      var ran = false;
      final signal = Signal(0)
        ..onDispose(() => throw StateError('cleanup'))
        ..onDispose(() => ran = true);

      Object? thrown;
      try {
        signal.dispose();
      } catch (e) {
        thrown = e;
      }

      expect(_messageOf(thrown), 'cleanup');
      expect(ran, isTrue);
    });
  });

  group('cleanup inside a running effect', () {
    // Each case disposes a node whose cleanup reads `audit`. The read must not
    // subscribe the running effect.
    late Signal<int> audit;
    var runs = 0;

    setUp(() {
      audit = Signal(0);
      runs = 0;
    });
    tearDown(() => audit.dispose());

    void expectOneRun() {
      audit.value = 1;
      expect(runs, 1);
    }

    test('a failed first run does not subscribe the running effect', () {
      final source = Signal(0, autoDispose: true)..onDispose(() => audit.value);
      final parent = Effect(() {
        runs++;
        try {
          Effect(() {
            source.value;
            throw const FormatException('child');
          });
        } on FormatException {
          // The parent handles the failed child.
        }
      });
      addTearDown(parent.dispose);

      expectOneRun();
      expect(source.disposed, isTrue);
    });

    test('Effect.dispose does not subscribe the running effect', () {
      final source = Signal(0, autoDispose: true)..onDispose(() => audit.value);
      final child = Effect(() => source.value);
      final parent = Effect(() {
        runs++;
        child.dispose();
      });
      addTearDown(parent.dispose);

      expectOneRun();
      expect(source.disposed, isTrue);
    });

    test('Computed.dispose does not subscribe the running effect', () {
      final computed = Computed(() => 0)..onDispose(() => audit.value);
      final parent = Effect(() {
        runs++;
        computed.dispose();
      });
      addTearDown(parent.dispose);

      expectOneRun();
      expect(computed.disposed, isTrue);
    });

    test('Signal.dispose does not subscribe the running effect', () {
      final signal = Signal(0)..onDispose(() => audit.value);
      final parent = Effect(() {
        runs++;
        signal.dispose();
      });
      addTearDown(parent.dispose);

      expectOneRun();
      expect(signal.disposed, isTrue);
    });
  });
}
