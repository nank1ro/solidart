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

    test('length setter modifies list', () {
      final list = ListSignal([1, 2, 3, 4]);
      var runs = 0;

      Effect(() {
        list.length;
        runs++;
      });

      expect(runs, 1);
      expect(list.length, 4);

      // Test shortening the list
      list.length = 2;
      expect(runs, 2);
      expect(list.value, [1, 2]);

      // Test setting to current length (no-op)
      list.length = 2;
      expect(runs, 2);
    });

    test('[] operator reads elements', () {
      final list = ListSignal([1, 2, 3]);
      var runs = 0;

      Effect(() {
        final _ = list[1];
        runs++;
      });

      expect(runs, 1);
      expect(list[0], 1);
      expect(list[1], 2);
      expect(list[2], 3);

      list[1] = 5;
      expect(runs, 2);
    });

    test('insert and insertAll add elements', () {
      final list = ListSignal([1, 3]);
      var runs = 0;

      Effect(() {
        list.length;
        runs++;
      });

      expect(runs, 1);

      list.insert(1, 2);
      expect(runs, 2);
      expect(list.value, [1, 2, 3]);

      list.insertAll(0, [-1, 0]);
      expect(runs, 3);
      expect(list.value, [-1, 0, 1, 2, 3]);
    });

    test('removeRange removes elements', () {
      final list = ListSignal([1, 2, 3, 4, 5]);
      var runs = 0;

      Effect(() {
        list.length;
        runs++;
      });

      expect(runs, 1);

      list.removeRange(1, 3);
      expect(runs, 2);
      expect(list.value, [1, 4, 5]);
    });

    test('replaceRange replaces elements', () {
      final list = ListSignal([1, 2, 3, 4]);
      var runs = 0;

      Effect(() {
        list.length;
        runs++;
      });

      expect(runs, 1);

      list.replaceRange(1, 3, [10, 20]);
      expect(runs, 2);
      expect(list.value, [1, 10, 20, 4]);
    });

    test('setAll modifies elements', () {
      final list = ListSignal([1, 2, 3, 4]);
      var runs = 0;

      Effect(() {
        list.length;
        runs++;
      });

      expect(runs, 1);

      list.setAll(1, [10, 20]);
      expect(runs, 2);
      expect(list.value, [1, 10, 20, 4]);
    });

    test('setRange modifies elements', () {
      final list = ListSignal([1, 2, 3, 4]);
      var runs = 0;

      Effect(() {
        list.length;
        runs++;
      });

      expect(runs, 1);

      list.setRange(1, 3, [10, 20]);
      expect(runs, 2);
      expect(list.value, [1, 10, 20, 4]);
    });

    test('fillRange fills elements', () {
      final list = ListSignal([1, 2, 3, 4]);
      var runs = 0;

      Effect(() {
        list.length;
        runs++;
      });

      expect(runs, 1);

      list.fillRange(1, 3, 0);
      expect(runs, 2);
      expect(list.value, [1, 0, 0, 4]);
    });

    test('shuffle randomizes list', () {
      final list = ListSignal([1, 2, 3, 4, 5]);
      var runs = 0;

      Effect(() {
        list.length;
        runs++;
      });

      expect(runs, 1);

      list.shuffle();
      expect(runs, 2);
      expect(list.length, 5);
      // Can't test exact order due to randomness, but all elements should still
      // exist.
      expect(list.value.toSet(), {1, 2, 3, 4, 5});
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

    test('putIfAbsent adds new keys', () {
      final map = MapSignal({'a': 1});
      var runs = 0;

      Effect(() {
        map.length;
        runs++;
      });

      expect(runs, 1);

      final value1 = map.putIfAbsent('a', () => 99);
      expect(value1, 1);
      expect(runs, 1);

      final value2 = map.putIfAbsent('b', () => 2);
      expect(value2, 2);
      expect(runs, 2);
      expect(map.value, {'a': 1, 'b': 2});
    });

    test('update modifies existing keys', () {
      final map = MapSignal({'a': 1, 'b': 2});
      var runs = 0;

      Effect(() {
        final _ = map['a'];
        runs++;
      });

      expect(runs, 1);

      map.update('a', (value) => value + 10);
      expect(runs, 2);
      expect(map['a'], 11);

      map.update('c', (value) => value, ifAbsent: () => 3);
      expect(runs, 3);
      expect(map['c'], 3);
    });

    test('updateAll modifies all values', () {
      final map = MapSignal({'a': 1, 'b': 2});
      var runs = 0;

      Effect(() {
        map.length;
        runs++;
      });

      expect(runs, 1);

      map.updateAll((key, value) => value * 2);
      expect(runs, 2);
      expect(map.value, {'a': 2, 'b': 4});
    });

    test('removeWhere removes matching entries', () {
      final map = MapSignal({'a': 1, 'b': 2, 'c': 3});
      var runs = 0;

      Effect(() {
        map.length;
        runs++;
      });

      expect(runs, 1);

      map.removeWhere((key, value) => value.isEven);
      expect(runs, 2);
      expect(map.value, {'a': 1, 'c': 3});
    });

    test('containsKey checks for keys', () {
      final map = MapSignal({'a': 1, 'b': 2});
      var runs = 0;

      Effect(() {
        map.containsKey('a');
        runs++;
      });

      expect(runs, 1);
      expect(map.containsKey('a'), true);
      expect(map.containsKey('c'), false);

      map['c'] = 3;
      expect(runs, 2);
    });

    test('containsValue checks for values', () {
      final map = MapSignal({'a': 1, 'b': 2});
      var runs = 0;

      Effect(() {
        map.containsValue(1);
        runs++;
      });

      expect(runs, 1);
      expect(map.containsValue(1), true);
      expect(map.containsValue(3), false);

      map['a'] = 10;
      expect(runs, 2);
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

    test('lookup finds elements', () {
      final set = SetSignal({1, 2, 3});
      var runs = 0;

      Effect(() {
        set.lookup(2);
        runs++;
      });

      expect(runs, 1);
      expect(set.lookup(2), 2);
      expect(set.lookup(4), isNull);

      set.add(4);
      expect(runs, 2);
    });

    test('addAll with existing elements', () {
      final set = SetSignal({1, 2});
      var runs = 0;

      Effect(() {
        set.length;
        runs++;
      });

      expect(runs, 1);

      set.addAll([1, 2, 3, 4]);
      expect(runs, 2);
      expect(set.value, {1, 2, 3, 4});
    });

    test('removeAll removes multiple elements', () {
      final set = SetSignal({1, 2, 3, 4, 5});
      var runs = 0;

      Effect(() {
        set.length;
        runs++;
      });

      expect(runs, 1);

      set.removeAll([2, 4]);
      expect(runs, 2);
      expect(set.value, {1, 3, 5});
    });

    test('retainAll keeps only specified elements', () {
      final set = SetSignal({1, 2, 3, 4, 5});
      var runs = 0;

      Effect(() {
        set.length;
        runs++;
      });

      expect(runs, 1);

      set.retainAll([2, 4, 6]);
      expect(runs, 2);
      expect(set.value, {2, 4});
    });
  });
}
