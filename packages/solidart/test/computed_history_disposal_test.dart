import 'package:solidart/solidart.dart';
import 'package:test/test.dart';

void main() {
  group('Computed auto-dispose after a failed evaluation (#200)', () {
    test(
      'a failed observe() on an autoDispose Computed disposes its '
      'autoDispose source',
      () {
        final source = Signal(0, autoDispose: true);
        var disposals = 0;
        source.onDispose(() => disposals++);
        final c = Computed(() {
          if (source.value == 0) throw StateError('zero');
          return source.value;
        }, autoDispose: true);

        addTearDown(c.dispose);
        addTearDown(source.dispose);

        expect(
          () => c.observe((_, _) {}),
          throwsA(isA<SolidartCaughtException>()),
        );

        expect((c.listenerCount, source.listenerCount, disposals), (0, 0, 1));
      },
    );

    test('disposing an autoDispose Computed after a failed read disposes '
        'its autoDispose source', () {
      final source = Signal(0, autoDispose: true);
      var disposals = 0;
      source.onDispose(() => disposals++);
      final c = Computed(() {
        if (source.value == 0) throw StateError('zero');
        return source.value;
      }, autoDispose: true);

      addTearDown(c.dispose);
      addTearDown(source.dispose);

      expect(() => c.value, throwsA(isA<SolidartCaughtException>()));
      expect(source.disposed, isFalse);

      c.dispose();

      expect(source.disposed, isTrue);
      expect(disposals, 1);
    });

    test('disposing an autoDispose Computed after a failed run() disposes '
        'its autoDispose source', () {
      final source = Signal(0, autoDispose: true);
      final c = Computed<int>(() {
        source.value;
        throw StateError('selector');
      }, autoDispose: true);

      addTearDown(c.dispose);
      addTearDown(source.dispose);

      expect(c.run, throwsA(isA<SolidartCaughtException>()));
      expect(source.disposed, isFalse);

      c.dispose();

      expect(source.disposed, isTrue);
    });

    for (final viaRun in [true, false]) {
      test(
        'disposing after a failed ${viaRun ? 'run()' : 'read'} that switches '
        'branch disposes the earlier and the new autoDispose source',
        () {
          final useB = Signal(false);
          final a = Signal(1, autoDispose: true);
          final b = Signal(2, autoDispose: true);
          var aDisposals = 0;
          a.onDispose(() => aDisposals++);
          final c = Computed<int>(() {
            if (!useB.value) return a.value;
            b.value;
            throw StateError('b');
          }, autoDispose: true);

          addTearDown(c.dispose);
          addTearDown(useB.dispose);
          addTearDown(a.dispose);
          addTearDown(b.dispose);

          if (viaRun) {
            c.run();
          } else {
            c.value;
          }
          useB.value = true;
          expect(
            viaRun ? c.run : () => c.value,
            throwsA(isA<SolidartCaughtException>()),
          );

          c.dispose();

          expect((a.disposed, b.disposed, aDisposals), (true, true, 1));
        },
      );
    }

    test('disposing an autoDispose Computed after a successful run() '
        'disposes its autoDispose source', () {
      final source = Signal(0, autoDispose: true);
      final c = Computed(() => source.value, autoDispose: true);

      addTearDown(c.dispose);
      addTearDown(source.dispose);

      c.run();
      expect(source.disposed, isFalse);

      c.dispose();

      expect(source.disposed, isTrue);
    });

    test('disposing the only effect of a failing autoDispose Computed '
        'disposes the Computed and its autoDispose source', () {
      final source = Signal(0, autoDispose: true);
      var disposals = 0;
      source.onDispose(() => disposals++);
      final c = Computed(() {
        if (source.value == 0) throw StateError('zero');
        return source.value;
      }, autoDispose: true);
      final errors = <Object>[];
      final effect = Effect(() => c.value, onError: errors.add);

      addTearDown(effect.dispose);
      addTearDown(c.dispose);
      addTearDown(source.dispose);

      expect(errors.single, isA<SolidartCaughtException>());

      effect.dispose();

      expect(c.disposed, isTrue);
      expect(source.disposed, isTrue);
      expect(disposals, 1);
    });

    test('a failing autoDispose Computed that still has a subscriber is not '
        'disposed, and recovers', () {
      final source = Signal(0, autoDispose: true);
      var disposals = 0;
      source.onDispose(() => disposals++);
      final c = Computed(() {
        if (source.value == 0) throw StateError('zero');
        return source.value;
      }, autoDispose: true);
      final seen = <int>[];
      final errors = <Object>[];
      final effect = Effect(() => seen.add(c.value), onError: errors.add);

      addTearDown(effect.dispose);
      addTearDown(c.dispose);
      addTearDown(source.dispose);

      expect(errors.single, isA<SolidartCaughtException>());
      expect(c.disposed, isFalse);
      expect(source.disposed, isFalse);
      expect(c.listenerCount, 1);

      source.value = 1;
      expect(seen, [1]);

      effect.dispose();
      expect(c.disposed, isTrue);
      expect(source.disposed, isTrue);
      expect(disposals, 1);
    });

    test('disposal reaches a source first read by a failed evaluation', () {
      final first = Signal(1, autoDispose: true);
      final second = Signal(0, autoDispose: true);
      final c = Computed(() {
        if (first.value == 1) return 0;
        if (second.value == 0) throw StateError('zero');
        return second.value;
      }, autoDispose: true);

      addTearDown(c.dispose);
      addTearDown(first.dispose);
      addTearDown(second.dispose);

      expect(c.value, 0);
      first.value = 2;
      expect(() => c.value, throwsA(isA<SolidartCaughtException>()));

      c.dispose();

      expect(first.disposed, isTrue);
      expect(second.disposed, isTrue);
    });

    test('a successful observe() and dispose disposes the source once', () {
      final source = Signal(1, autoDispose: true);
      var disposals = 0;
      source.onDispose(() => disposals++);
      final c = Computed(() {
        if (source.value == 0) throw StateError('zero');
        return source.value;
      }, autoDispose: true);

      addTearDown(c.dispose);
      addTearDown(source.dispose);

      final dispose = c.observe((_, _) {});
      expect(c.listenerCount, 1);
      expect(source.listenerCount, 1);

      dispose();

      expect((c.listenerCount, source.listenerCount, disposals), (0, 0, 1));
      expect(c.disposed, isTrue);
      expect(source.disposed, isTrue);
    });

    test('dispose reaches an input of a failed evaluation that a nested '
        'evaluation during the disposal drain no longer reads', () {
      final first = Signal(0, autoDispose: true);
      final retry = Signal(false);
      final second = Signal(0);
      final queued = Signal(0, autoDispose: true);
      final holder = Effect(() => queued.value);
      late Computed<int> c;
      // Runs in the drain at the end of the evaluation below. The nested
      // evaluation reads `second` instead of `first`.
      queued.onDispose(() {
        retry.value = true;
        expect(() => c.value, throwsA(isA<SolidartCaughtException>()));
      });
      c = Computed(() {
        if (retry.value) {
          second.value;
          throw StateError('second');
        }
        first.value;
        holder.dispose();
        throw StateError('first');
      });

      addTearDown(retry.dispose);
      addTearDown(second.dispose);

      expect(() => c.value, throwsA(isA<SolidartCaughtException>()));
      expect(queued.disposed, isTrue);

      c.dispose();
      expect(first.disposed, isTrue);
    });
  });

  group('Computed previous value history (#201)', () {
    test('a nullable Computed has no previous value after its first null '
        'value', () {
      final c = Computed<int?>(() => null);

      addTearDown(c.dispose);

      expect(c.value, isNull);
      expect(c.hasPreviousValue, isFalse);
      expect(c.untrackedHasPreviousValue, isFalse);
      expect(c.previousValue, isNull);
      expect(c.untrackedPreviousValue, isNull);
    });

    test('a nullable Computed records exactly its earlier values for '
        'null -> 1 -> null', () {
      final s = Signal<int?>(null);
      final c = Computed<int?>(() => s.value);

      addTearDown(c.dispose);
      addTearDown(s.dispose);

      expect(c.value, isNull);
      expect(c.hasPreviousValue, isFalse);
      expect(c.untrackedHasPreviousValue, isFalse);

      s.value = 1;
      expect(c.value, 1);
      expect(c.hasPreviousValue, isTrue);
      expect(c.untrackedHasPreviousValue, isTrue);
      expect(c.previousValue, isNull);
      expect(c.untrackedPreviousValue, isNull);

      s.value = null;
      expect(c.value, isNull);
      expect(c.hasPreviousValue, isTrue);
      expect(c.previousValue, 1);
      expect(c.untrackedPreviousValue, 1);
    });

    test('a nullable Computed whose first evaluation throws has no previous '
        'value after it recovers', () {
      final s = Signal(0);
      final c = Computed<int?>(() {
        if (s.value == 0) throw StateError('zero');
        return s.value;
      });

      addTearDown(c.dispose);
      addTearDown(s.dispose);

      expect(() => c.value, throwsA(isA<SolidartCaughtException>()));

      s.value = 1;
      expect(c.value, 1);
      expect(c.hasPreviousValue, isFalse);
      expect(c.untrackedHasPreviousValue, isFalse);
      expect(c.previousValue, isNull);
      expect(c.untrackedPreviousValue, isNull);
    });
  });
}
