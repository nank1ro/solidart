import 'dart:async';
import 'dart:developer' as developer;
import 'dart:isolate';

import 'package:solidart/solidart.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service_io.dart';

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

/// Calls [onDispose] when a signal is disposed.
class _DisposalObserver extends SolidartObserver {
  _DisposalObserver(this.onDispose);

  final void Function(SignalBase<Object?> signal) onDispose;

  @override
  void didCreateSignal(SignalBase<Object?> signal) {}

  @override
  void didUpdateSignal(SignalBase<Object?> signal) {}

  @override
  void didDisposeSignal(SignalBase<Object?> signal) => onDispose(signal);
}

void _addObserver(SolidartObserver observer) {
  SolidartConfig.observers.add(observer);
  addTearDown(() => SolidartConfig.observers.remove(observer));
}

Signal<int>? _retained;

// Not inlined, so no local variable keeps the signal alive.
@pragma('vm:never-inline')
(Effect, WeakReference<Signal<int>>) _disposeEffectThatReadsASignal() {
  final signal = _retained = Signal(0);
  final effect = Effect(() => _retained!.value)..dispose();
  _retained = null;
  return (effect, WeakReference(signal));
}

/// Runs the garbage collector. Returns false when no VM service is available,
/// for example under `flutter test` without `--coverage`.
Future<bool> _collectGarbage() async {
  final info = await developer.Service.controlWebServer(enable: true);
  final uri = info.serverWebSocketUri;
  if (uri == null) return false;
  final service = await vmServiceConnectUri(uri.toString());
  try {
    await service.getAllocationProfile(
      developer.Service.getIsolateId(Isolate.current)!,
      gc: true,
    );
  } finally {
    await service.dispose();
  }
  return true;
}

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

    test('in a batch keeps its error when the deferred disposal throws', () {
      final setup = StateError('setup');
      final source = Signal(0, autoDispose: true)
        ..onDispose(() => throw StateError('cleanup'));

      Object? thrown;
      final zone = _runInZone(() {
        try {
          batch(
            () => Effect(() {
              source.value;
              throw setup;
            }),
          );
        } catch (e) {
          thrown = e;
        }
      });

      expect(thrown, same(setup));
      expect(zone.reported.map(_messageOf), ['cleanup']);
      expect(source.disposed, isTrue);
    });

    test('run by hand keeps its error when a queued effect also throws', () {
      final trigger = Signal(false);
      addTearDown(trigger.dispose);
      final queued = Effect(() {
        if (trigger.value) throw StateError('queued');
      });
      addTearDown(queued.dispose);
      final effect = Effect(() {
        trigger.value = true;
        throw StateError('setup');
      }, autorun: false);
      addTearDown(effect.dispose);

      Object? thrown;
      final zone = _runInZone(() {
        try {
          effect.run();
        } catch (e) {
          thrown = e;
        }
      });

      expect(_messageOf(thrown), 'setup');
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

    test('a disposal observer does not replace the first error', () {
      final signal = Signal(0)..onDispose(() => throw StateError('signal'));
      final computed = Computed(() => 0)
        ..onDispose(() => throw StateError('computed'));
      _addObserver(_DisposalObserver((_) => throw StateError('observer')));

      final thrown = <Object?>[];
      final zone = _runInZone(() {
        for (final dispose in [signal.dispose, computed.dispose]) {
          try {
            dispose();
          } catch (e) {
            thrown.add(e);
          }
        }
      });

      expect(thrown.map(_messageOf), ['signal', 'computed']);
      expect(zone.reported.map(_messageOf), ['observer', 'observer']);
    });

    test('disposing a Computed notifies its disposal once', () {
      final source = Signal(0);
      addTearDown(source.dispose);
      final computed = Computed(() => source.value, autoDispose: true);
      Effect(() => computed.value, autoDispose: true);
      var disposals = 0;
      _addObserver(
        _DisposalObserver((signal) {
          if (identical(signal, computed)) disposals++;
        }),
      );

      computed.dispose();

      expect(disposals, 1);
    });

    test('every disposal observer runs when one throws', () {
      final seen = <String>[];
      _addObserver(
        _DisposalObserver((_) {
          seen.add('first');
          throw StateError('first');
        }),
      );
      _addObserver(
        _DisposalObserver((_) {
          seen.add('second');
          throw StateError('second');
        }),
      );
      _addObserver(_DisposalObserver((_) => seen.add('third')));

      final thrown = <Object?>[];
      final zone = _runInZone(() {
        for (final dispose in [Signal(0).dispose, Computed(() => 0).dispose]) {
          try {
            dispose();
          } catch (e) {
            thrown.add(e);
          }
        }
      });

      expect(seen, ['first', 'second', 'third', 'first', 'second', 'third']);
      expect(thrown.map(_messageOf), ['first', 'first']);
      expect(zone.reported.map(_messageOf), ['second', 'second']);
    });
  });

  group('a Computed without autoDispose', () {
    test('disposes its dependencies when disposed', () {
      final source = Signal(0, autoDispose: true);
      final computed = Computed(() => source.value);
      expect(computed.value, 0);

      computed.dispose();

      expect(source.disposed, isTrue);
    });
  });

  group('#202 a nested effect stopped by its parent', () {
    test('disposing the parent disposes the child dependency', () {
      final own = Signal(0, autoDispose: true);
      final childDep = Signal(0, autoDispose: true);
      Effect(() {
        own.value;
        Effect(() => childDep.value);
      }).dispose();

      expect((own.disposed, childDep.disposed), (true, true));
    });

    test('a parent rerun disposes the dependency of the old child', () {
      final trigger = Signal(0);
      addTearDown(trigger.dispose);
      final childDep = Signal(0, autoDispose: true);
      var created = 0;
      final parent = Effect(() {
        trigger.value;
        if (created++ == 0) Effect(() => childDep.value);
      });
      addTearDown(parent.dispose);

      trigger.value = 1;

      expect((childDep.disposed, childDep.listenerCount), (true, 0));
    });

    test('a parent rerun keeps the dependency of a recreated child', () {
      final trigger = Signal(0);
      addTearDown(trigger.dispose);
      final childDep = Signal(0, autoDispose: true);
      addTearDown(childDep.dispose);
      var childRuns = 0;
      final parent = Effect(() {
        trigger.value;
        Effect(() {
          childDep.value;
          childRuns++;
        });
      });
      addTearDown(parent.dispose);

      trigger.value = 1;
      childDep.value = 5;

      expect((childDep.disposed, childRuns), (false, 3));
    });

    test('a parent rerun in a batch keeps the dependency of a recreated '
        'child', () {
      final trigger = Signal(0);
      addTearDown(trigger.dispose);
      final childDep = Signal(0, autoDispose: true);
      addTearDown(childDep.dispose);
      var childRuns = 0;
      final parent = Effect(() {
        trigger.value;
        Effect(() {
          childDep.value;
          childRuns++;
        });
      });
      addTearDown(parent.dispose);

      batch(() {
        trigger.value = 1;
      });
      childDep.value = 5;

      expect((childDep.disposed, childRuns), (false, 3));
    });

    test('a parent rerun in a batch disposes the dependency of the old '
        'child', () {
      final trigger = Signal(0);
      addTearDown(trigger.dispose);
      final childDep = Signal(0, autoDispose: true);
      var created = 0;
      final parent = Effect(() {
        trigger.value;
        if (created++ == 0) Effect(() => childDep.value);
      });
      addTearDown(parent.dispose);

      batch(() {
        trigger.value = 1;
      });

      expect((childDep.disposed, childDep.listenerCount), (true, 0));
    });

    test('keeps a dependency that another effect still reads', () {
      final shared = Signal(0, autoDispose: true);
      addTearDown(shared.dispose);
      final other = Effect(() => shared.value);
      addTearDown(other.dispose);
      Effect(() {
        Effect(() => shared.value);
      }).dispose();

      expect((shared.disposed, shared.listenerCount), (false, 1));
    });

    test('an effect queued by onDispose runs before the next dependency is '
        'offered for disposal', () {
      final poke = Signal(0);
      addTearDown(poke.dispose);
      final a = Signal(0, autoDispose: true);
      final b = Signal(0, autoDispose: true);
      addTearDown(b.dispose);
      a.onDispose(() => poke.value = 1);
      final seen = <int>[];
      final watcher = Effect(() {
        if (poke.value > 0) seen.add(b.value);
      });
      addTearDown(watcher.dispose);
      Effect(() {
        Effect(() {
          a.value;
          b.value;
        });
      }).dispose();

      b.value = 7;

      expect((b.disposed, seen.join(',')), (false, '0,7'));
    });

    test('disposes every dependency when onDispose throws, then rethrows', () {
      final own = Signal(0, autoDispose: true);
      final first = Signal(0, autoDispose: true)
        ..onDispose(() => throw StateError('first'));
      final second = Signal(0, autoDispose: true)
        ..onDispose(() => throw StateError('second'));
      final parent = Effect(() {
        own.value;
        Effect(() {
          first.value;
          second.value;
        });
      });

      Object? thrown;
      final zone = _runInZone(() {
        try {
          parent.dispose();
        } catch (e) {
          thrown = e;
        }
      });

      expect(_messageOf(thrown), 'first');
      expect(zone.reported.map(_messageOf), ['second']);
      expect(
        (own.disposed, first.disposed, second.disposed),
        (
          true,
          true,
          true,
        ),
      );
    });

    test('a parent rerun still runs when onDispose throws, then rethrows', () {
      final trigger = Signal(0);
      addTearDown(trigger.dispose);
      final childDep = Signal(0, autoDispose: true)
        ..onDispose(() => throw StateError('cleanup'));
      var runs = 0;
      final parent = Effect(() {
        trigger.value;
        if (runs++ == 0) Effect(() => childDep.value);
      });
      addTearDown(parent.dispose);

      Object? thrown;
      try {
        trigger.value = 1;
      } catch (e) {
        thrown = e;
      }

      expect(_messageOf(thrown), 'cleanup');
      expect((runs, childDep.disposed), (2, true));
      trigger.value = 2;
      expect(runs, 3);
    });

    test('a child of a Computed reports a disposal error to the zone', () {
      final childDep = Signal(0, autoDispose: true)
        ..onDispose(() => throw StateError('cleanup'));
      final own = Signal(0, autoDispose: true);
      final computed = Computed(() {
        Effect(() => childDep.value);
        return own.value;
      });
      expect(computed.value, 0);

      Object? thrown;
      final zone = _runInZone(() {
        try {
          computed.dispose();
        } catch (e) {
          thrown = e;
        }
      });

      expect(thrown, isNull);
      expect(zone.reported.map(_messageOf), ['cleanup']);
      expect((childDep.disposed, own.listenerCount), (true, 0));
    });

    test('a standalone Computed rerun keeps the dependency of a recreated '
        'child', () {
      final trigger = Signal(0);
      addTearDown(trigger.dispose);
      final childDep = Signal(0, autoDispose: true);
      addTearDown(childDep.dispose);
      final seen = <int>[];
      final owner = Computed(() {
        Effect(() => seen.add(childDep.value));
        return trigger.value;
      });
      addTearDown(owner.dispose);
      expect(owner.value, 0);

      trigger.value = 1;
      expect(owner.value, 1);
      childDep.value = 2;

      expect((childDep.disposed, seen.join(',')), (false, '0,0,2'));
    });

    test('a Computed disposal yields to an effect queued by onDispose', () {
      final gate = Signal(false);
      addTearDown(gate.dispose);
      final first = Signal(0, autoDispose: true)
        ..onDispose(() => gate.value = true);
      final second = Signal(1, autoDispose: true);
      addTearDown(second.dispose);
      final seen = <int>[];
      final watcher = Effect(() {
        if (gate.value) seen.add(second.value);
      });
      addTearDown(watcher.dispose);
      final pair = Computed(
        () => first.value + second.value,
        autoDispose: true,
      );
      Effect(() => pair.value).dispose();

      second.value = 2;

      expect((pair.disposed, first.disposed), (true, true));
      expect((second.disposed, seen.join(',')), (false, '1,2'));
    });

    test('a disposed effect releases the dependencies it read', () async {
      final (effect, signal) = _disposeEffectThatReadsASignal();

      if (!await _collectGarbage()) {
        markTestSkipped('No VM service to run the garbage collector.');
        return;
      }

      expect(effect.disposed, isTrue);
      expect(signal.target, isNull);
    });
  });

  group('#203 a delayed autoDispose effect', () {
    test('runs its first callback', () async {
      final input = Signal(1);
      addTearDown(input.dispose);
      final seen = <int>[];
      final effect = Effect(
        () => seen.add(input.value),
        delay: Duration.zero,
        autoDispose: true,
      );
      addTearDown(effect.dispose);

      expect(effect.disposed, isFalse);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(seen, [1]);
    });

    test(
      'reruns when its dependency changes after the first callback',
      () async {
        final input = Signal(1);
        addTearDown(input.dispose);
        final seen = <int>[];
        final effect = Effect(
          () => seen.add(input.value),
          delay: Duration.zero,
          autoDispose: true,
        );
        addTearDown(effect.dispose);
        await Future<void>.delayed(const Duration(milliseconds: 10));

        input.value = 2;
        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(seen, [1, 2]);
        expect(effect.disposed, isFalse);
      },
    );

    test('disposes itself when its dependency is disposed', () async {
      final input = Signal(1);
      final effect = Effect(
        () => input.value,
        delay: Duration.zero,
        autoDispose: true,
      );
      addTearDown(effect.dispose);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(effect.disposed, isFalse);

      input.dispose();

      expect(effect.disposed, isTrue);
    });
  });

  group('#204 a delayed effect', () {
    const delay = Duration(milliseconds: 5);
    Future<void> afterDelay() =>
        Future<void>.delayed(const Duration(milliseconds: 30));

    test('reruns when its dependencies change', () async {
      final input = Signal(1);
      addTearDown(input.dispose);
      final seen = <int>[];
      final effect = Effect(() => seen.add(input.value), delay: delay);
      addTearDown(effect.dispose);

      await afterDelay();
      input.value = 2;
      await afterDelay();
      input.value = 3;
      await afterDelay();

      expect(seen, [1, 2, 3]);
    });

    test('coalesces the changes made while a rerun is pending', () async {
      final input = Signal(1);
      addTearDown(input.dispose);
      final seen = <int>[];
      final effect = Effect(() => seen.add(input.value), delay: delay);
      addTearDown(effect.dispose);
      await afterDelay();

      input
        ..value = 2
        ..value = 3;
      await afterDelay();

      expect(seen, [1, 3]);
    });

    test('dispose cancels a pending rerun', () async {
      final input = Signal(1);
      addTearDown(input.dispose);
      final seen = <int>[];
      final effect = Effect(() => seen.add(input.value), delay: delay);
      await afterDelay();
      final zone = _runInZone(() => input.value = 2);

      effect.dispose();

      expect(zone.timers.single.isActive, isFalse);
      await afterDelay();
      expect(seen, [1]);
    });

    test(
      'disposed while a rerun is pending disposes its dependencies',
      () async {
        final input = Signal(1, autoDispose: true);
        final effect = Effect(() => input.value, delay: delay);
        await afterDelay();
        input.value = 2;

        effect.dispose();

        expect(input.disposed, isTrue);
      },
    );

    test('without onError reports a callback error to the zone and keeps '
        'running', () async {
      final input = Signal(1);
      addTearDown(input.dispose);
      final seen = <int>[];
      final effect = Effect(() {
        seen.add(input.value);
        if (input.untrackedValue == 2) throw StateError('delayed');
      }, delay: delay);
      addTearDown(effect.dispose);
      await afterDelay();

      final zone = _runInZone(() => input.value = 2);
      await afterDelay();
      input.value = 3;
      await afterDelay();

      expect(zone.reported.map(_messageOf), ['delayed']);
      expect(seen, [1, 2, 3]);
      expect(effect.disposed, isFalse);
    });

    test('schedules a new run when its own callback changes a dependency '
        'through another effect', () async {
      const slowDelay = Duration(milliseconds: 50);
      final input = Signal(1);
      final trigger = Signal(0);
      addTearDown(input.dispose);
      addTearDown(trigger.dispose);
      var runs = 0;
      var echoed = false;
      final delayed = Effect(() {
        input.value;
        runs++;
        trigger.value = runs;
      }, delay: slowDelay);
      addTearDown(delayed.dispose);
      final echo = Effect(() {
        if (trigger.value > 0 && !echoed) {
          echoed = true;
          input.value = 2;
        }
      });
      addTearDown(echo.dispose);

      await Future<void>.delayed(const Duration(milliseconds: 70));
      await Future<void>.value();
      expect(runs, 1);

      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(runs, 2);
    });

    test('keeps every dependency linked while its timer is pending', () async {
      final first = Signal(1, autoDispose: true);
      final second = Signal(1, autoDispose: true);
      var runs = 0;
      final effect = Effect(() {
        first.value;
        second.value;
        runs++;
      }, delay: delay);
      addTearDown(effect.dispose);
      await afterDelay();
      expect(runs, 1);

      first.value = 2;
      effect.dispose();
      await afterDelay();

      expect(first.disposed, isTrue);
      expect(second.disposed, isTrue);
      expect(runs, 1);
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

  group('error priority', () {
    test('a disposal error after a queued effect error goes to the zone', () {
      final trigger = Signal(0);
      addTearDown(trigger.dispose);
      final childDep = Signal(0, autoDispose: true)
        ..onDispose(() => throw StateError('disposal'));
      var created = 0;
      final parent = Effect(() {
        trigger.value;
        if (created++ == 0) Effect(() => childDep.value);
      });
      addTearDown(parent.dispose);
      var armed = false;
      final thrower = Effect(() {
        trigger.value;
        if (armed) throw StateError('effect');
      });
      addTearDown(thrower.dispose);
      armed = true;

      Object? thrown;
      final zone = _runInZone(() {
        try {
          trigger.value = 1;
        } catch (e) {
          thrown = e;
        }
      });

      expect(_messageOf(thrown), 'effect');
      expect(zone.reported.map(_messageOf), ['disposal']);
      expect(childDep.disposed, isTrue);
    });

    test('Computed.run rethrows the selector error over a cleanup error', () {
      final source = Signal(0, autoDispose: true)
        ..onDispose(() => throw StateError('cleanup'));
      final effect = Effect(() => source.value);
      final computed = Computed<int>(() {
        effect.dispose();
        throw StateError('selector');
      });

      Object? thrown;
      final zone = _runInZone(() {
        try {
          computed.run();
        } catch (e) {
          thrown = e;
        }
      });

      expect(thrown, isA<SolidartCaughtException>());
      expect(
        _messageOf((thrown! as SolidartCaughtException).exception),
        'selector',
      );
      expect(zone.reported.map(_messageOf), ['cleanup']);
    });

    // An effect with no dependency but a remembered `source`: its run
    // auto-disposes it, and the disposal of `source` throws.
    Effect buildEffect({required bool bodyThrows}) {
      final trigger = Signal(0);
      final source = Signal(0, autoDispose: true)
        ..onDispose(() => throw StateError('disposal'));
      final release = Signal(false);
      final holder = Effect(() {
        release.value;
        if (!release.untrackedValue) source.value;
      });
      final queuedEffect = Effect(() {
        if (trigger.value > 0) throw StateError('queued');
      });
      addTearDown(queuedEffect.dispose);
      final effect =
          Effect(
              () {
                trigger.value = 1;
                if (bodyThrows) throw StateError('body');
              },
              autorun: false,
              autoDispose: true,
            )
            // ignore: invalid_use_of_protected_member
            ..setDependencies(holder.subscriber);
      release.value = true;
      return effect;
    }

    test('Effect.run keeps the batch-end and disposal errors for the zone', () {
      final effect = buildEffect(bodyThrows: true);

      Object? thrown;
      final zone = _runInZone(() {
        try {
          effect.run();
        } catch (e) {
          thrown = e;
        }
      });

      expect(_messageOf(thrown), 'body');
      expect(
        zone.reported.map(_messageOf),
        unorderedEquals(['queued', 'disposal']),
      );
    });

    test('Effect.run rethrows the batch-end error over a disposal error', () {
      final effect = buildEffect(bodyThrows: false);

      Object? thrown;
      final zone = _runInZone(() {
        try {
          effect.run();
        } catch (e) {
          thrown = e;
        }
      });

      expect(_messageOf(thrown), 'queued');
      expect(zone.reported.map(_messageOf), ['disposal']);
    });
  });
}
