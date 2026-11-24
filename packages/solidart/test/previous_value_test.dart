import 'package:solidart/solidart.dart';
import 'package:test/test.dart';

void main() {
  group('untrackedPreviousValue', () {
    test('is null with trackPreviousValue: false and observe agrees', () {
      final s = Signal(1, trackPreviousValue: false);
      addTearDown(s.dispose);
      final calls = <(int?, int)>[];
      final dispose = s.observe((prev, value) => calls.add((prev, value)));
      addTearDown(dispose);

      s.value = 2;

      expect(s.previousValue, isNull);
      expect(s.untrackedPreviousValue, isNull);
      expect(calls, [(null, 2)]);
    });

    test('ListSignal in-place add exposes the old list', () {
      final s = ListSignal([1]);
      addTearDown(s.dispose);
      final calls = <(List<int>?, List<int>)>[];
      final dispose = s.observe(
        (prev, value) => calls.add((prev, [...value])),
      );
      addTearDown(dispose);

      s.add(2);

      expect(s.untrackedPreviousValue, equals([1]));
      expect(calls, hasLength(1));
      expect(calls.single.$1, equals([1]));
      expect(calls.single.$2, equals([1, 2]));
    });

    test('ListSignal in-place add after value reassignment', () {
      final s = ListSignal([1]);
      addTearDown(s.dispose);

      s
        ..value = [1, 2]
        ..add(3);

      expect(s.untrackedPreviousValue, equals([1, 2]));
    });

    test('MapSignal in-place []= exposes the old map', () {
      final s = MapSignal({'a': 1});
      addTearDown(s.dispose);
      final calls = <(Map<String, int>?, Map<String, int>)>[];
      final dispose = s.observe(
        (prev, value) => calls.add((prev, {...value})),
      );
      addTearDown(dispose);

      s['b'] = 2;

      expect(calls, hasLength(1));
      expect(calls.single.$1, equals({'a': 1}));
      expect(calls.single.$2, equals({'a': 1, 'b': 2}));
    });

    test('SetSignal in-place add exposes the old set', () {
      final s = SetSignal({1});
      addTearDown(s.dispose);

      s.add(2);

      expect(s.untrackedPreviousValue, equals({1}));
    });

    test('SetSignal no-op add keeps the previous value', () {
      final s = SetSignal({1});
      addTearDown(s.dispose);
      final seen = <Set<int>?>[];
      final dispose = s.observe(
        (prev, _) => seen.add(prev == null ? null : Set.of(prev)),
      );
      addTearDown(dispose);

      batch(() {
        s
          ..value = {1, 2}
          ..add(2);
      });

      expect(seen.single, equals({1}));
    });

    test('SetSignal no-op removeAll keeps the previous value', () {
      final s = SetSignal({1});
      addTearDown(s.dispose);

      s
        ..add(2)
        ..removeAll([3]);

      expect(s.untrackedPreviousValue, equals({1}));
    });

    test('MapSignal replacement keeps the old identity map', () {
      final key1 = DateTime(2020);
      final key2 = DateTime(2020);
      final s = MapSignal(
        Map<DateTime, int>.identity()
          ..[key1] = 1
          ..[key2] = 2,
      );
      addTearDown(s.dispose);
      final seen = <Map<DateTime, int>?>[];
      final dispose = s.observe((prev, _) => seen.add(prev));
      addTearDown(dispose);

      s.value = {};

      expect(seen.single, hasLength(2));
      expect(seen.single!.values, unorderedEquals([1, 2]));
    });

    test('SetSignal replacement keeps the old identity set', () {
      final s = SetSignal(
        Set<DateTime>.identity()
          ..add(DateTime(2020))
          ..add(DateTime(2020)),
      );
      addTearDown(s.dispose);
      final seen = <Set<DateTime>?>[];
      final dispose = s.observe((prev, _) => seen.add(prev));
      addTearDown(dispose);

      s.value = {};

      expect(seen.single, hasLength(2));
    });

    test('SetSignal in-place add keeps the identity equality', () {
      final s = SetSignal(Set<DateTime>.identity()..add(DateTime(2020)));
      addTearDown(s.dispose);

      s.add(DateTime(2020));

      final prev = s.untrackedPreviousValue!..add(DateTime(2020));
      expect(prev, hasLength(2));
    });

    test('Computed untrackedPreviousValue equals previousValue', () {
      final s = Signal(1);
      addTearDown(s.dispose);
      final c = Computed(() => s.value);
      addTearDown(c.dispose);

      c.value;
      s.value = 2;

      expect(c.untrackedPreviousValue, 1);
      expect(c.previousValue, 1);
    });

    test('Computed untrackedPreviousValue does not subscribe an effect', () {
      final s = Signal(1);
      addTearDown(s.dispose);
      final c = Computed(() => s.value, autoDispose: false);
      addTearDown(c.dispose);
      var runs = 0;
      final effect = Effect(() {
        runs++;
        c.untrackedPreviousValue;
      });
      addTearDown(effect.dispose);

      s.value = 2;

      expect(runs, 1);
    });

    test('Resource untrackedPreviousState equals previousState', () async {
      final r = Resource(() async => 1);
      addTearDown(r.dispose);
      await r.untilReady();

      expect(r.previousState, isNotNull);
      expect(r.untrackedPreviousState, same(r.previousState));
    });

    test('GUARD: default tracking keeps the previous value', () {
      final s = Signal(1);
      addTearDown(s.dispose);
      final calls = <(int?, int)>[];
      final dispose = s.observe((prev, value) => calls.add((prev, value)));
      addTearDown(dispose);

      s.value = 2;

      expect(s.untrackedPreviousValue, 1);
      expect(calls, [(1, 2)]);
    });
  });
}
