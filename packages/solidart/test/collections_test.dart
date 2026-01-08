import 'package:solidart/solidart.dart';
import 'package:test/test.dart';

void main() {
  group('ListSignal', () {
    test('reacts to mutations', () {
      final list = ListSignal([1, 2]);
      var runs = 0;

      Effect(() {
        list.length;
        runs++;
      });

      expect(runs, 1);

      list.add(3);
      expect(runs, 2);

      list[0] = 1;
      expect(runs, 2);

      list[0] = 5;
      expect(runs, 3);

      list.remove(99);
      expect(runs, 3);

      list.remove(5);
      expect(runs, 4);
    });

    test('tracks previous value after read', () {
      final list = ListSignal([1, 2]);

      final values = (
        initial: list.previousValue,
        afterAdd: (list..add(3)).previousValue,
      );

      expect(values.initial, isNull);
      expect(values.afterAdd, [1, 2]);
    });

    test('respects trackPreviousValue false', () {
      final list = ListSignal([1], trackPreviousValue: false);

      final values = (
        previous: (list..add(2)).previousValue,
        untracked: list.untrackedPreviousValue,
      );

      expect(values.previous, isNull);
      expect(values.untracked, isNull);
    });

    test('no-op mutations do not notify', () {
      final list = ListSignal([1, 2, 3]);
      var runs = 0;

      Effect(() {
        list.length;
        runs++;
      });

      expect(runs, 1);

      list
        ..addAll([])
        ..insertAll(1, [])
        ..replaceRange(0, 0, [])
        ..setAll(0, [1, 2, 3])
        ..setRange(0, 3, [1, 2, 3])
        ..fillRange(1, 1)
        ..removeWhere((_) => false)
        ..retainWhere((_) => true)
        ..sort();

      expect(runs, 1);
    });

    test('empty list no-op mutations do not notify', () {
      final list = ListSignal<int>([]);
      var runs = 0;

      Effect(() {
        list.length;
        runs++;
      });

      expect(runs, 1);

      list
        ..clear()
        ..removeWhere((_) => true)
        ..sort()
        ..shuffle();

      expect(runs, 1);
    });
  });

  group('MapSignal', () {
    test('reacts to mutations', () {
      final map = MapSignal({'a': 1});
      var runs = 0;

      Effect(() {
        final _ = map['a'];
        runs++;
      });

      expect(runs, 1);

      map['a'] = 1;
      expect(runs, 1);

      map['a'] = 2;
      expect(runs, 2);

      map.remove('missing');
      expect(runs, 2);

      map.remove('a');
      expect(runs, 3);
    });

    test('tracks previous value after read', () {
      final map = MapSignal({'a': 1});

      final previous = (map..['a'] = 2).previousValue;

      expect(previous, {'a': 1});
    });

    test('no-op mutations do not notify', () {
      final map = MapSignal({'a': 1, 'b': 2});
      var runs = 0;

      Effect(() {
        map.length;
        runs++;
      });

      expect(runs, 1);

      map
        ..addAll({})
        ..updateAll((key, value) => value)
        ..removeWhere((key, value) => false)
        ..putIfAbsent('a', () => 99);

      expect(runs, 1);
    });

    test('addAll updates existing keys', () {
      final map = MapSignal({'a': 1});
      var runs = 0;

      Effect(() {
        final _ = map['a'];
        runs++;
      });

      expect(runs, 1);

      map.addAll({'a': 1});
      expect(runs, 1);

      map.addAll({'a': 2});
      expect(runs, 2);
    });

    test('empty map no-op mutations do not notify', () {
      final map = MapSignal<String, int>({});
      var runs = 0;

      Effect(() {
        map.length;
        runs++;
      });

      expect(runs, 1);

      map
        ..clear()
        ..addAll({})
        ..removeWhere((key, value) => true)
        ..updateAll((key, value) => value);

      expect(runs, 1);
    });
  });

  group('SetSignal', () {
    test('reacts to mutations', () {
      final set = SetSignal({1});
      var runs = 0;

      Effect(() {
        set.contains(1);
        runs++;
      });

      expect(runs, 1);

      set.add(1);
      expect(runs, 1);

      set.add(2);
      expect(runs, 2);

      set.remove(3);
      expect(runs, 2);

      set.remove(1);
      expect(runs, 3);
    });

    test('tracks previous value after read', () {
      final set = SetSignal({1});

      final previous = (set..add(2)).previousValue;

      expect(previous, {1});
    });

    test('no-op mutations do not notify', () {
      final set = SetSignal({1, 2});
      var runs = 0;

      Effect(() {
        set.length;
        runs++;
      });

      expect(runs, 1);

      set
        ..addAll([])
        ..removeAll([])
        ..retainAll({1, 2})
        ..removeWhere((_) => false)
        ..retainWhere((_) => true);

      expect(runs, 1);
    });

    test('empty set no-op mutations do not notify', () {
      final set = SetSignal<int>({});
      var runs = 0;

      Effect(() {
        set.length;
        runs++;
      });

      expect(runs, 1);

      set
        ..clear()
        ..addAll([])
        ..removeAll([])
        ..retainAll({});

      expect(runs, 1);
    });
  });
}
