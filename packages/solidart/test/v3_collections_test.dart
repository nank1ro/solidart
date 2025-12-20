import 'package:solidart/v3.dart';
import 'package:test/test.dart';

void main() {
  group('ReactiveList', () {
    test('reacts to mutations', () {
      final list = ReactiveList([1, 2]);
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
      final list = ReactiveList([1, 2]);

      expect(list.previousValue, isNull);

      list.add(3);

      expect(list.previousValue, [1, 2]);
    });

    test('respects trackPreviousValue false', () {
      final list = ReactiveList([1], trackPreviousValue: false);

      list.add(2);

      expect(list.previousValue, isNull);
      expect(list.untrackedPreviousValue, isNull);
    });

    test('no-op mutations do not notify', () {
      final list = ReactiveList([1, 2, 3]);
      var runs = 0;

      Effect(() {
        list.length;
        runs++;
      });

      expect(runs, 1);

      list.addAll([]);
      list.insertAll(1, []);
      list.replaceRange(0, 0, []);
      list.setAll(0, [1, 2, 3]);
      list.setRange(0, 3, [1, 2, 3]);
      list.fillRange(1, 1);
      list.removeWhere((_) => false);
      list.retainWhere((_) => true);
      list.sort();

      expect(runs, 1);
    });

    test('empty list no-op mutations do not notify', () {
      final list = ReactiveList<int>([]);
      var runs = 0;

      Effect(() {
        list.length;
        runs++;
      });

      expect(runs, 1);

      list.clear();
      list.removeWhere((_) => true);
      list.sort();
      list.shuffle();

      expect(runs, 1);
    });
  });

  group('ReactiveMap', () {
    test('reacts to mutations', () {
      final map = ReactiveMap({'a': 1});
      var runs = 0;

      Effect(() {
        map['a'];
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
      final map = ReactiveMap({'a': 1});

      map['a'] = 2;

      expect(map.previousValue, {'a': 1});
    });

    test('no-op mutations do not notify', () {
      final map = ReactiveMap({'a': 1, 'b': 2});
      var runs = 0;

      Effect(() {
        map.length;
        runs++;
      });

      expect(runs, 1);

      map.addAll({});
      map.updateAll((key, value) => value);
      map.removeWhere((_, __) => false);
      map.putIfAbsent('a', () => 99);

      expect(runs, 1);
    });

    test('empty map no-op mutations do not notify', () {
      final map = ReactiveMap<String, int>({});
      var runs = 0;

      Effect(() {
        map.length;
        runs++;
      });

      expect(runs, 1);

      map.clear();
      map.addAll({});
      map.removeWhere((_, __) => true);
      map.updateAll((_, value) => value);

      expect(runs, 1);
    });
  });

  group('ReactiveSet', () {
    test('reacts to mutations', () {
      final set = ReactiveSet({1});
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
      final set = ReactiveSet({1});

      set.add(2);

      expect(set.previousValue, {1});
    });

    test('no-op mutations do not notify', () {
      final set = ReactiveSet({1, 2});
      var runs = 0;

      Effect(() {
        set.length;
        runs++;
      });

      expect(runs, 1);

      set.addAll([]);
      set.removeAll([]);
      set.retainAll({1, 2});
      set.removeWhere((_) => false);
      set.retainWhere((_) => true);

      expect(runs, 1);
    });

    test('empty set no-op mutations do not notify', () {
      final set = ReactiveSet<int>({});
      var runs = 0;

      Effect(() {
        set.length;
        runs++;
      });

      expect(runs, 1);

      set.clear();
      set.addAll([]);
      set.removeAll([]);
      set.retainAll({});

      expect(runs, 1);
    });
  });
}
