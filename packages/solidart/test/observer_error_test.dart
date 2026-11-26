import 'dart:async';

import 'package:solidart/solidart.dart';
import 'package:test/test.dart';

/// Runs [body] in a zone. Returns the error that [body] throws and the
/// messages of the errors that are reported to the zone.
({Object? error, List<String> reported}) _guarded(void Function() body) {
  Object? error;
  final reported = <String>[];
  runZonedGuarded(() {
    try {
      body();
    } on Object catch (e) {
      error = e;
    }
  }, (e, _) => reported.add((e as StateError).message));
  return (error: error, reported: reported);
}

class _Observer extends SolidartObserver {
  _Observer(this.log, this.name, {this.fails = false, this.where});

  final List<String> log;
  final String name;
  final bool fails;
  final bool Function(SignalBase<Object?> signal)? where;

  @override
  void didCreateSignal(SignalBase<Object?> signal) {}

  @override
  void didUpdateSignal(SignalBase<Object?> signal) {
    if (where != null && !where!(signal)) return;
    log.add(name);
    if (fails) throw StateError(name);
  }

  @override
  void didDisposeSignal(SignalBase<Object?> signal) {}
}

/// A value that records when DevTools serializes it.
class _Probe {
  _Probe(this.sent);

  final List<String> sent;

  Object? toJson() {
    sent.add('devtools');
    return 0;
  }
}

void main() {
  late List<String> log;

  void observe(SolidartObserver observer) {
    SolidartConfig.observers.add(observer);
    addTearDown(() => SolidartConfig.observers.remove(observer));
  }

  setUp(() {
    log = [];
    final devToolsEnabled = SolidartConfig.devToolsEnabled;
    addTearDown(() => SolidartConfig.devToolsEnabled = devToolsEnabled);
    SolidartConfig.devToolsEnabled = true;
  });

  group('a throwing effect', () {
    test('does not skip the observers and DevTools of a Signal', () {
      observe(_Observer(log, 'observer'));
      final s = Signal(_Probe([]));
      addTearDown(s.dispose);
      var runs = 0;
      final effect = Effect(() {
        s.value;
        if (runs++ > 0) throw StateError('effect');
      });
      addTearDown(effect.dispose);
      log.clear();

      final result = _guarded(() => s.value = _Probe(log));

      expect((result.error! as StateError).message, 'effect');
      expect(log, ['observer', 'devtools']);
      expect(result.reported, isEmpty);
    });

    test('does not skip the observers and DevTools of a collection', () {
      observe(_Observer(log, 'observer'));
      final s = ListSignal<Object>([]);
      addTearDown(s.dispose);
      final effect = Effect(() {
        if (s.value.isNotEmpty) throw StateError('effect');
      });
      addTearDown(effect.dispose);

      final result = _guarded(() => s.value = [_Probe(log)]);

      expect((result.error! as StateError).message, 'effect');
      expect(log, ['observer', 'devtools']);
      expect(result.reported, isEmpty);
    });

    test('does not skip the observers of a collection assigned in a '
        'mutation callback', () {
      observe(_Observer(log, 'observer'));
      final s = ListSignal([0]);
      addTearDown(s.dispose);
      final effect = Effect(() {
        if (s.value.first == 1) throw StateError('effect');
      });
      addTearDown(effect.dispose);

      final result = _guarded(() {
        s.retainWhere((_) {
          s.value = [1];
          return true;
        });
      });

      expect((result.error! as StateError).message, 'effect');
      expect(log, ['observer']);
      expect(result.reported, isEmpty);
    });
  });

  group('a throwing observer', () {
    test('does not skip later observers and DevTools', () {
      observe(_Observer(log, 'first', fails: true));
      observe(_Observer(log, 'second', fails: true));
      observe(_Observer(log, 'third'));
      final s = Signal(_Probe([]));
      addTearDown(s.dispose);
      log.clear();

      final result = _guarded(() => s.value = _Probe(log));

      expect((result.error! as StateError).message, 'first');
      expect(log, ['first', 'second', 'third', 'devtools']);
      expect(result.reported, ['second']);
    });

    test('is reported after the error of the effect', () {
      observe(_Observer(log, 'observer', fails: true));
      final s = Signal(0);
      addTearDown(s.dispose);
      final effect = Effect(() {
        if (s.value == 1) throw StateError('effect');
      });
      addTearDown(effect.dispose);

      final result = _guarded(() => s.value = 1);

      expect((result.error! as StateError).message, 'effect');
      expect(log, ['observer']);
      expect(result.reported, ['observer']);
    });

    test('does not skip later observers of a collection', () {
      observe(_Observer(log, 'first', fails: true));
      observe(_Observer(log, 'second'));
      final s = ListSignal<int>([]);
      addTearDown(s.dispose);

      final result = _guarded(() => s.add(1));

      expect((result.error! as StateError).message, 'first');
      expect(log, ['first', 'second']);
      expect(s.untrackedValue, [1]);
    });

    test('does not skip later observers of a Computed', () {
      bool isComputed(SignalBase<Object?> signal) => signal is Computed;
      observe(_Observer(log, 'first', fails: true, where: isComputed));
      observe(_Observer(log, 'second', where: isComputed));
      final source = Signal(0);
      final computed = Computed(() => source.value * 2);
      addTearDown(source.dispose);
      addTearDown(computed.dispose);
      computed.value;
      log.clear();

      source.value = 1;
      final result = _guarded(() => computed.value);

      expect((result.error! as StateError).message, 'first');
      expect(log, ['first', 'second']);
    });
  });
}
