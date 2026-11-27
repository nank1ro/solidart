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

/// A stream whose subscription throws synchronously when cancelled.
class _ThrowingCancelStream extends Stream<int> {
  @override
  StreamSubscription<int> listen(
    void Function(int event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => _ThrowingCancelSubscription();
}

class _ThrowingCancelSubscription implements StreamSubscription<int> {
  @override
  Future<void> cancel() => throw StateError('cancel');

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
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

@pragma('vm:never-inline')
(Effect, WeakReference<Signal<int>>) _disposeTheSignalOfALiveEffect() {
  final signal = _retained = Signal(0);
  final effect = Effect(() => _retained!.value);
  signal.dispose();
  _retained = null;
  return (effect, WeakReference(signal));
}

// A Computed run by hand, then switched to a branch that does not read the
// signal.
@pragma('vm:never-inline')
(Computed<int>, WeakReference<Signal<int>>) _switchAComputedAway() {
  final signal = _retained = Signal(42);
  final useSignal = Signal(true);
  final computed = Computed(() => useSignal.value ? _retained!.value : 0)
    ..run();
  useSignal.value = false;
  expect(computed.value, 0);
  _retained = null;
  return (computed, WeakReference(signal));
}

// A Computed that reads the signal only in a failed branch, then recovers.
@pragma('vm:never-inline')
(Computed<int>, WeakReference<Signal<int>>) _recoverAComputed() {
  final signal = _retained = Signal(0);
  final mode = Signal(0);
  final computed = Computed(() {
    if (mode.value == 1) {
      _retained!.value;
      throw StateError('selector');
    }
    return 7;
  });
  expect(computed.value, 7);
  mode.value = 1;
  expect(() => computed.value, throwsA(isA<SolidartCaughtException>()));
  mode.value = 2;
  expect(computed.value, 7);
  _retained = null;
  return (computed, WeakReference(signal));
}

// An observed autoDispose Computed switched to a branch with the same value:
// it evaluates again, but the effect does not read it again.
@pragma('vm:never-inline')
(Effect, WeakReference<Signal<int>>) _switchAnObservedComputedAway() {
  final signal = _retained = Signal(0);
  final useSignal = Signal(true);
  final computed = Computed(
    () => useSignal.value ? _retained!.value : 0,
    autoDispose: true,
  );
  final effect = Effect(() => computed.value);
  useSignal.value = false;
  expect(signal.listenerCount, 0);
  _retained = null;
  return (effect, WeakReference(signal));
}

// A Computed run by hand, then left by its last observer, so alien_signals
// unlinks its inputs. Its input is disposed afterwards.
@pragma('vm:never-inline')
(Computed<int>, WeakReference<Signal<int>>) _disposeTheInputOfALeftComputed() {
  final signal = _retained = Signal(0);
  final computed = Computed(() => _retained!.value)..run();
  Effect(() => computed.value).dispose();
  expect(signal.listenerCount, 0);
  signal.dispose();
  _retained = null;
  return (computed, WeakReference(signal));
}

// Leave only a weak reference to the original backing before forcing GC.
@pragma('vm:never-inline')
(ListSignal<int>, WeakReference<List<int>>) _replaceAndMutateList({
  required bool trackPreviousValue,
}) {
  final signal = ListSignal(
    List.filled(1000000, 1),
    trackPreviousValue: trackPreviousValue,
  );
  final retired = WeakReference(signal.untrackedValue);
  signal.value = [0];
  signal[0] = 1;
  return (signal, retired);
}

@pragma('vm:never-inline')
(ListSignal<int>, WeakReference<List<int>>) _replacePointUpdatedList({
  required bool trackPreviousValue,
}) {
  final signal = ListSignal([0], trackPreviousValue: trackPreviousValue);
  final large = List.filled(1000000, 1);
  final retired = WeakReference(large);
  signal
    ..value = large
    ..[0] = 2
    ..value = [3]
    ..value = [4];
  return (signal, retired);
}

@pragma('vm:never-inline')
(ListSignal<int>, WeakReference<List<int>>) _retireListBeforeBatchFlush({
  required bool trackPreviousValue,
}) {
  final signal = ListSignal(
    List.filled(1000000, 1),
    autoDispose: false,
    trackPreviousValue: trackPreviousValue,
  );
  final retired = WeakReference(signal.untrackedValue);
  final effect = Effect(() => signal.value);
  batch(() {
    signal
      ..value = [0]
      ..[0] = 1;
    effect.dispose();
  });
  return (signal, retired);
}

/// Runs the garbage collector. Returns false when no VM service is available,
/// for example under `flutter test` without `--coverage`.
Effect? _child;

@pragma('vm:never-inline')
(Effect, WeakReference<Effect>) _disposeTheChildOfALiveEffect() {
  final parent = Effect(() => _child = Effect(() {}));
  final child = WeakReference(_child!);
  _child!.dispose();
  _child = null;
  return (parent, child);
}

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

    test('in a batch keeps the selector error of Computed.run() when an '
        'effect onError throws', () {
      var fail = false;
      final c = Computed(() {
        if (fail) throw StateError('selector');
        return 0;
      });
      final effect = Effect(
        () => c.value,
        onError: (_) => throw StateError('handler'),
      );
      addTearDown(effect.dispose);

      fail = true;
      Object? thrown;
      final zone = _runInZone(() {
        try {
          batch(c.run);
        } catch (e) {
          thrown = e;
        }
      });

      expect(thrown, isA<SolidartCaughtException>());
      expect(
        _messageOf((thrown! as SolidartCaughtException).exception),
        'selector',
      );
      expect(zone.reported.map(_messageOf), ['handler']);
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

    test('run by hand stays alive, unless autoDispose finds no '
        'dependency', () {
      final source = Signal(0);
      addTearDown(source.dispose);
      Effect build({required bool autoDispose}) => Effect(
        () {
          if (source.untrackedValue == 0) throw StateError('not ready');
          source.value;
        },
        autorun: false,
        autoDispose: autoDispose,
      );
      final kept = build(autoDispose: false);
      addTearDown(kept.dispose);
      final disposed = build(autoDispose: true);

      expect(kept.run, throwsStateError);
      expect(disposed.run, throwsStateError);

      expect((kept.disposed, disposed.disposed), (false, true));
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

  test('a self-disposed effect does not resubscribe during its rerun', () {
    var disposals = 0;
    final trigger = Signal(0, autoDispose: true)..onDispose(() => disposals++);
    final other = Signal(0);
    addTearDown(trigger.dispose);
    addTearDown(other.dispose);
    late final Effect effect;
    effect = Effect(() {
      if (trigger.value == 0) {
        other.value;
        return;
      }
      effect.dispose();
      trigger.value;
    });
    addTearDown(effect.dispose);

    trigger.value = 1;

    expect(effect.disposed, isTrue);
    expect(trigger.listenerCount, 0);
    expect(trigger.disposed, isTrue);
    expect(disposals, 1);
  });

  test('a Computed that disposes its observing effect stays unobserved', () {
    final trigger = Signal(0, autoDispose: true);
    final input = Signal(1);
    addTearDown(trigger.dispose);
    addTearDown(input.dispose);
    late final Effect effect;
    final computed = Computed(() {
      effect.dispose();
      return input.value;
    });
    addTearDown(computed.dispose);
    effect = Effect(() {
      if (trigger.value == 0) return;
      computed.value;
      trigger.value;
    });
    addTearDown(effect.dispose);

    trigger.value = 1;

    expect(computed.listenerCount, 0);
    expect(trigger.disposed, isTrue);
    expect(input.listenerCount, 1);
  });

  test('a Computed run does not restore an effect its selector disposes', () {
    final trigger = Signal(0, autoDispose: true);
    addTearDown(trigger.dispose);
    late final Effect effect;
    final computed = Computed(() {
      effect.dispose();
      return 0;
    });
    addTearDown(computed.dispose);
    effect = Effect(() {
      if (trigger.value == 0) return;
      computed.run();
      trigger.value;
    });
    addTearDown(effect.dispose);

    trigger.value = 1;

    expect(trigger.listenerCount, 0);
    expect(trigger.disposed, isTrue);
  });

  for (final throwsAfterDisposal in [false, true]) {
    test(
      'queued effects do not restore a stopped delayed effect '
      'with throwsAfterDisposal=$throwsAfterDisposal',
      () async {
        final trigger = Signal(0, autoDispose: true);
        final startDrain = Signal(false);
        var disposedInDrain = false;
        final pending = Signal(
          0,
          comparator: (old, next) {
            if (disposedInDrain) trigger.value;
            return old == next;
          },
        );
        addTearDown(trigger.dispose);
        addTearDown(startDrain.dispose);
        addTearDown(pending.dispose);
        late final Effect parent;
        final stopParent = Effect(() {
          if (!startDrain.value) return;
          parent.dispose();
          disposedInDrain = true;
          if (throwsAfterDisposal) throw StateError('queued effect');
        });
        addTearDown(stopParent.dispose);
        final readPending = Effect(() => pending.value);
        addTearDown(readPending.dispose);
        parent = Effect(() {
          if (trigger.value == 0) return;
          startDrain.value = true;
          pending.value = 1;
        }, delay: Duration.zero);
        addTearDown(parent.dispose);
        await Future<void>.delayed(const Duration(milliseconds: 25));

        final zone = _runInZone(() => trigger.value = 1);
        await Future<void>.delayed(const Duration(milliseconds: 25));

        expect(parent.disposed, isTrue);
        expect(trigger.listenerCount, 0);
        expect(trigger.disposed, isTrue);
        expect(zone.reported.map(_messageOf), [
          if (throwsAfterDisposal) 'queued effect',
        ]);
      },
    );
  }

  test(
    'a delayed effect that stops itself is cleared before its drain',
    () async {
      final trigger = Signal(0, autoDispose: true);
      var disposedInRun = false;
      final pending = Signal(
        0,
        comparator: (old, next) {
          if (disposedInRun) trigger.value;
          return old == next;
        },
      );
      addTearDown(trigger.dispose);
      addTearDown(pending.dispose);
      final reader = Effect(() => pending.value);
      addTearDown(reader.dispose);
      late final Effect parent;
      parent = Effect(() {
        if (trigger.value == 0) return;
        pending.value = 1;
        parent.dispose();
        disposedInRun = true;
      }, delay: Duration.zero);
      addTearDown(parent.dispose);
      await Future<void>.delayed(const Duration(milliseconds: 25));

      trigger.value = 1;
      await Future<void>.delayed(const Duration(milliseconds: 25));

      expect(parent.disposed, isTrue);
      expect(trigger.listenerCount, 0);
      expect(trigger.disposed, isTrue);
    },
  );

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

    test('runs an onDispose callback registered while disposing, after the '
        'others', () {
      final source = Signal(0);
      addTearDown(source.dispose);
      final seen = <int>[];
      final watcher = Effect(() => seen.add(source.value));
      addTearDown(watcher.dispose);
      for (final signal in <SignalBase<int>>[Signal(0), Computed(() => 0)]) {
        final calls = <String>[];
        signal
          ..onDispose(() {
            calls.add('first');
            signal.onDispose(() => calls.add('late'));
          })
          ..onDispose(() => calls.add('second'))
          ..dispose();

        expect(calls, ['first', 'second', 'late']);
      }

      source.value = 1;

      expect(seen, [0, 1]);
    });

    test('runs an onDispose callback registered by a disposal observer', () {
      for (final owner in <SignalBase<int>>[Signal(0), Computed(() => 0)]) {
        var cleaned = false;
        _addObserver(
          _DisposalObserver((signal) {
            if (identical(signal, owner)) owner.onDispose(() => cleaned = true);
          }),
        );

        owner.dispose();

        expect(cleaned, isTrue, reason: owner.runtimeType.toString());
      }
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

    test('a Resource finishes its disposal when its source cleanup throws', () {
      final source = Signal(0, autoDispose: true)
        ..onDispose(() => throw StateError('source'));
      final resource = Resource<int>(() async => 1, source: source);
      var cleaned = false;
      resource
        ..state
        ..onDispose(() => cleaned = true);

      expect(
        resource.dispose,
        throwsA(
          isA<StateError>().having((e) => e.message, 'message', 'source'),
        ),
      );
      expect((resource.disposed, source.disposed, cleaned), (true, true, true));
    });

    test('a Resource stops observing its source when a cancel throws', () {
      final source = Signal(0);
      addTearDown(source.dispose);
      final resource = Resource<int>.stream(
        _ThrowingCancelStream.new,
        source: source,
      )..state;
      expect(source.listenerCount, 1);

      expect(
        resource.dispose,
        throwsA(
          isA<StateError>().having((e) => e.message, 'message', 'cancel'),
        ),
      );
      expect(resource.disposed, isTrue);
      expect(source.listenerCount, 0);
    });
  });

  group('a Resource disposed while it works', () {
    test(
      '#205 during its first fetch does not subscribe to its source',
      () async {
        final request = Completer<int>();
        final source = Signal(0);
        addTearDown(source.dispose);
        var requests = 0;
        Future<int> fetch() {
          requests++;
          return request.future;
        }

        final resource = Resource<int>(fetch, source: source)
          ..state
          ..dispose();
        request.complete(1);
        await Future<void>.delayed(Duration.zero);
        source.value = 1;

        expect((source.listenerCount, requests), (0, 1));
        expect(resource.untrackedState, isA<ResourceLoading<int>>());
      },
    );

    test('during a refetch does not write the result', () async {
      var request = Completer<int>();
      final resource = Resource<int>(() => request.future)..state;
      request.complete(1);
      await Future<void>.delayed(Duration.zero);
      request = Completer<int>();
      unawaited(resource.refresh());
      resource.dispose();
      request.complete(2);
      await Future<void>.delayed(Duration.zero);

      expect(resource.untrackedState.asReady?.value, 1);
    });

    test(
      '#206 with a pending debounced refresh does not subscribe again',
      () async {
        final source = Signal(0);
        addTearDown(source.dispose);
        final controller = StreamController<int>.broadcast();
        addTearDown(controller.close);
        var subscriptions = 0;
        final resource = Resource<int>.stream(
          () {
            subscriptions++;
            return controller.stream;
          },
          source: source,
          debounceDelay: Duration.zero,
        )..state;
        source.value = 1;
        resource.dispose();
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect((subscriptions, controller.hasListener), (1, false));
      },
    );

    test('a refresh after disposal does not subscribe again', () async {
      final controller = StreamController<int>.broadcast();
      addTearDown(controller.close);
      var subscriptions = 0;
      Stream<int> subscribe() {
        subscriptions++;
        return controller.stream;
      }

      final resource = Resource<int>.stream(subscribe)
        ..state
        ..dispose();
      await resource.refresh();

      expect((subscriptions, controller.hasListener), (1, false));
    });

    test('keeps the debounced refresh of another Resource of its '
        'source', () async {
      final source = Signal(0);
      addTearDown(source.dispose);
      var fetches = 0;
      Resource<int> create() => Resource<int>(
        () async => ++fetches,
        source: source,
        debounceDelay: Duration.zero,
      )..state;
      final kept = create();
      addTearDown(kept.dispose);
      final disposed = create();
      await Future<void>.delayed(Duration.zero);
      source.value = 1;
      disposed.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(fetches, 3);
      expect(kept.untrackedState.asReady?.value, 3);
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

    test('run by hand disposes an input that its last observer unlinked', () {
      final source = Signal(0, autoDispose: true);
      final computed = Computed(() => source.value)..run();
      Effect(() => computed.value).dispose();
      expect((source.listenerCount, source.disposed), (0, false));

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

    test('a child of a Computed disposes its dependency, then the Computed '
        'rethrows', () {
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

      expect(_messageOf(thrown), 'cleanup');
      expect(zone.reported, isEmpty);
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

    test('a Computed onDispose callback can subscribe to the dependency of '
        'its child', () {
      final childDep = Signal(1, autoDispose: true);
      addTearDown(childDep.dispose);
      final owner = Computed(() {
        Effect(() => childDep.value);
        return 0;
      });
      expect(owner.value, 0);
      final seen = <int>[];
      owner
        ..onDispose(() => Effect(() => seen.add(childDep.value)))
        ..dispose();

      childDep.value = 2;

      expect((childDep.disposed, seen.join(',')), (false, '1,2'));
    });

    test('a later Signal onDispose callback can subscribe to the dependency '
        'of a child that an earlier one stops', () {
      final owner = Signal(0);
      final childDep = Signal(1, autoDispose: true);
      addTearDown(childDep.dispose);
      final parent = Effect(() => Effect(() => childDep.value));
      final seen = <int>[];
      owner
        ..onDispose(parent.dispose)
        ..onDispose(() => Effect(() => seen.add(childDep.value)))
        ..dispose();

      childDep.value = 2;

      expect((childDep.disposed, seen.join(',')), (false, '1,2'));
    });

    test('a disposal observer can subscribe to the dependency of a child that '
        'an onDispose callback stops', () {
      for (final owner in <SignalBase<int>>[Signal(0), Computed(() => 0)]) {
        final childDep = Signal(1, autoDispose: true);
        addTearDown(childDep.dispose);
        final parent = Effect(() => Effect(() => childDep.value));
        final seen = <int>[];
        final observer = _DisposalObserver((signal) {
          if (identical(signal, owner)) {
            Effect(() => seen.add(childDep.value));
          }
        });
        _addObserver(observer);
        owner
          ..onDispose(parent.dispose)
          ..dispose();
        SolidartConfig.observers.remove(observer);

        childDep.value = 2;

        expect((childDep.disposed, seen.join(',')), (false, '1,2'));
      }
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

  group('released dependencies', () {
    Future<void> expectReleased(WeakReference<Object> reference) async {
      if (!await _collectGarbage()) {
        markTestSkipped('No VM service to run the garbage collector.');
        return;
      }
      expect(reference.target, isNull);
    }

    test('a live effect releases a disposed signal', () async {
      final (effect, signal) = _disposeTheSignalOfALiveEffect();
      await expectReleased(signal);
      expect(effect.disposed, isFalse);
    });

    test('a live effect releases a disposed child effect', () async {
      final (parent, child) = _disposeTheChildOfALiveEffect();
      addTearDown(parent.dispose);
      await expectReleased(child);
      expect(parent.disposed, isFalse);
    });

    test('a Computed releases an input it stopped reading', () async {
      final (computed, signal) = _switchAComputedAway();
      await expectReleased(signal);
      expect(computed.value, 0);
    });

    test(
      'a recovered Computed releases the inputs of its failed branch',
      () async {
        final (computed, signal) = _recoverAComputed();
        await expectReleased(signal);
        expect(computed.value, 7);
      },
    );

    test('an observed Computed releases an input it stopped reading', () async {
      final (effect, signal) = _switchAnObservedComputedAway();
      await expectReleased(signal);
      expect(effect.disposed, isFalse);
    });

    test('#207 a Computed left by its observers releases a disposed '
        'input', () async {
      final (computed, signal) = _disposeTheInputOfALeftComputed();
      await expectReleased(signal);
      expect(computed.disposed, isFalse);
    });
  });

  group('released collection storage', () {
    for (final (description, retire, current, previous) in [
      ('before a read', _replaceAndMutateList, 1, 0),
      ('after later replacements', _replacePointUpdatedList, 4, 3),
      (
        'after its last subscriber leaves a batch',
        _retireListBeforeBatchFlush,
        1,
        0,
      ),
    ]) {
      for (final trackPreviousValue in [false, true]) {
        test('releases a retired list $description '
            '(trackPreviousValue: $trackPreviousValue)', () async {
          final (signal, retired) = retire(
            trackPreviousValue: trackPreviousValue,
          );
          addTearDown(signal.dispose);

          if (!await _collectGarbage()) {
            markTestSkipped('No VM service to run the garbage collector.');
            return;
          }

          expect(retired.target, isNull);
          expect(
            signal.untrackedPreviousValue,
            trackPreviousValue ? [previous] : null,
          );
          expect(signal.value, [current]);
        });
      }
    }
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

  group('#209 the child effects of a delayed effect', () {
    const delay = Duration(milliseconds: 5);
    Future<void> afterDelay() =>
        Future<void>.delayed(const Duration(milliseconds: 30));

    test('keep an autoDispose signal alive across the rerun', () async {
      final trigger = Signal(0);
      addTearDown(trigger.dispose);
      final x = Signal(0, autoDispose: true);
      final seen = <int>[];
      final parent = Effect(() {
        trigger.value;
        Effect(() => seen.add(x.value));
      }, delay: delay);
      addTearDown(parent.dispose);
      await afterDelay();

      trigger.value = 1;
      expect(x.disposed, isFalse);
      await afterDelay();
      x.value = 5;

      expect(x.disposed, isFalse);
      expect(seen, [0, 0, 5]);
    });

    test('stay subscribed while the rerun is pending', () async {
      final trigger = Signal(0);
      addTearDown(trigger.dispose);
      final x = Signal(0, autoDispose: true);
      final seen = <int>[];
      late Effect child;
      final parent = Effect(() {
        trigger.value;
        child = Effect(() => seen.add(x.value));
      }, delay: delay);
      addTearDown(parent.dispose);
      await afterDelay();
      final firstChild = child;

      trigger.value = 1;
      x.value = 5;

      expect(seen, [0, 5]);
      expect(firstChild.disposed, isFalse);
      expect(x.disposed, isFalse);
    });

    test('stop when the replacement callback starts', () async {
      final trigger = Signal(0);
      addTearDown(trigger.dispose);
      final x = Signal(0);
      addTearDown(x.dispose);
      final seen = <String>[];
      final children = <Effect>[];
      final parent = Effect(() {
        final run = trigger.value;
        children.add(Effect(() => seen.add('$run:${x.value}')));
      }, delay: delay);
      addTearDown(parent.dispose);
      await afterDelay();

      trigger.value = 1;
      expect(children.first.disposed, isFalse);
      await afterDelay();
      expect(children.map((child) => child.disposed), [true, false]);
      seen.clear();
      x.value = 7;

      expect(seen, ['1:7']);
    });

    test('of a coalesced rerun stay until the single timer fires', () async {
      final trigger = Signal(0);
      addTearDown(trigger.dispose);
      final x = Signal(0, autoDispose: true);
      var created = 0;
      var childRuns = 0;
      final parent = Effect(() {
        trigger.value;
        Effect(() {
          x.value;
          childRuns++;
        });
        created++;
      }, delay: delay);
      addTearDown(parent.dispose);
      await afterDelay();

      trigger
        ..value = 1
        ..value = 2;
      expect(x.disposed, isFalse);
      await afterDelay();

      expect(created, 2);
      expect(x.disposed, isFalse);
      childRuns = 0;
      x.value = 1;
      expect(childRuns, 1);
    });

    test('follow the dependencies of the parent that reruns by itself '
        'after the delay', () async {
      final trigger = Signal(0);
      addTearDown(trigger.dispose);
      final x = Signal(0, autoDispose: true);
      final seen = <int>[];
      final parent = Effect(() {
        trigger.value;
        Effect(() => seen.add(x.value));
      }, delay: delay);
      addTearDown(parent.dispose);
      await afterDelay();

      for (var i = 1; i <= 3; i++) {
        trigger.value = i;
        await afterDelay();
      }
      x.value = 9;

      expect(seen, [0, 0, 0, 0, 9]);
    });

    test(
      'are disposed at once when the parent is disposed during the delay',
      () async {
        final trigger = Signal(0);
        addTearDown(trigger.dispose);
        final x = Signal(0, autoDispose: true);
        late Effect child;
        late Effect parent;
        var runs = 0;
        _runInZone(() {
          parent = Effect(() {
            trigger.value;
            runs++;
            child = Effect(() => x.value);
          }, delay: delay);
        });
        await afterDelay();
        final zone = _runInZone(() => trigger.value = 1);
        expect(child.disposed, isFalse);

        parent.dispose();

        expect(zone.timers.single.isActive, isFalse);
        expect(child.disposed, isTrue);
        expect(x.disposed, isTrue);
        await afterDelay();
        expect(runs, 1);
      },
    );
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

    // A Computed whose next run commits [next] and stops its child effect.
    // The disposal of the child dependency, at the end of the run, throws.
    Computed<int> buildCommittingComputed(int Function() next) {
      final childDep = Signal(0, autoDispose: true)
        ..onDispose(() => throw StateError('cleanup'));
      var runs = 0;
      return Computed(() {
        if (runs++ == 0) {
          Effect(() => childDep.value);
          return 0;
        }
        return next();
      });
    }

    test('Computed.run notifies a committed change before it rethrows a '
        'cleanup error', () {
      final computed = buildCommittingComputed(() => 1);
      final seen = <int>[];
      final subscriber = Effect(() => seen.add(computed.value));
      addTearDown(subscriber.dispose);

      Object? thrown;
      try {
        computed.run();
      } catch (e) {
        thrown = e;
      }

      expect(_messageOf(thrown), 'cleanup');
      expect(computed.value, 1);
      expect(seen, [0, 1]);
    });

    test('Computed.run rethrows a cleanup error over a subscriber error', () {
      final computed = buildCommittingComputed(() => 1);
      final subscriber = Effect(() {
        if (computed.value == 1) throw StateError('subscriber');
      });
      addTearDown(subscriber.dispose);

      Object? thrown;
      final zone = _runInZone(() {
        try {
          computed.run();
        } catch (e) {
          thrown = e;
        }
      });

      expect(_messageOf(thrown), 'cleanup');
      expect(zone.reported.map(_messageOf), ['subscriber']);
    });

    // A Computed whose failed run stops its child effect. The disposal of the
    // child dependency, at the end of the run, calls [recover].
    Computed<int> buildRecoveringComputed(
      void Function(Computed<int> computed, Signal<bool> fail) recover,
    ) {
      final fail = Signal(false);
      final childDep = Signal(0, autoDispose: true);
      late final Computed<int> computed;
      computed = Computed(() {
        if (fail.value) throw StateError('selector');
        Effect(() => childDep.value);
        return 1;
      });
      expect(computed.value, 1);
      childDep.onDispose(() => recover(computed, fail));
      fail.value = true;
      return computed;
    }

    test('Computed.run keeps its selector error when a cleanup runs it '
        'again', () {
      final computed = buildRecoveringComputed((computed, fail) {
        fail.value = false;
        computed.run();
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
      expect(zone.reported, isEmpty);
    });

    test('Computed.run keeps its selector error when a cleanup reads it, then '
        'throws', () {
      final computed = buildRecoveringComputed((computed, fail) {
        fail.value = false;
        computed.value;
        throw StateError('cleanup');
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

  group('disposing the last input of a pending subscriber', () {
    test('does not break the flush of a pending Effect', () {
      final source = Signal(0);
      final seen = <int>[];
      final effect = Effect(() => seen.add(source.value));
      addTearDown(effect.dispose);

      // The net-zero writes leave the effect pending, not dirty.
      expect(
        () => batch(() {
          source
            ..value = 1
            ..value = 0
            ..dispose();
        }),
        returnsNormally,
      );
      expect(seen, [0]);
    });

    test('does not break a read of a pending Computed', () {
      final source = Signal(0);
      final computed = Computed(() => source.value);
      final seen = <int>[];
      final effect = Effect(() => seen.add(computed.value));
      addTearDown(effect.dispose);

      expect(
        () => batch(() {
          source
            ..value = 1
            ..value = 0
            ..dispose();
        }),
        returnsNormally,
      );
      expect(computed.value, 0);
      expect(seen, [0]);
    });

    test('does not break the flush of a delayed Effect with a pending '
        'timer', () async {
      const delay = Duration(milliseconds: 10);
      final source = Signal(0);
      final seen = <int>[];
      final effect = Effect(() => seen.add(source.value), delay: delay);
      addTearDown(effect.dispose);

      await Future<void>.delayed(delay * 3);
      source.value = 1;
      await Future<void>.delayed(delay * 3);
      // Starts a timer, then leaves the effect pending in the batch.
      source.value = 2;
      expect(
        () => batch(() {
          source
            ..value = 3
            ..value = 2
            ..dispose();
        }),
        returnsNormally,
      );
      await Future<void>.delayed(delay * 3);
      expect(seen, [0, 1, 2]);
    });
  });
}
