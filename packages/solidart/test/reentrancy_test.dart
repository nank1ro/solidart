import 'package:solidart/solidart.dart';
import 'package:test/test.dart';

void main() {
  group('effect re-entrancy during initial run', () {
    test(
      '''a signal write during the effect first run does not re-enter the effect callback while it is still on the stack''',
      () {
        final previousAutoDispose = SolidartConfig.autoDispose;
        addTearDown(() => SolidartConfig.autoDispose = previousAutoDispose);
        SolidartConfig.autoDispose = false;
        final source = Signal(0, name: 'source');
        var running = false;
        var maxConcurrentDepth = 0;
        var runs = 0;

        final effect = Effect(() {
          runs++;
          // Detect re-entrancy: if the callback is invoked while a previous
          // invocation is still on the stack, `running` is already true.
          expect(running, isFalse, reason: 'effect re-entered its own run');
          running = true;
          maxConcurrentDepth++;

          // Subscribe to `source`, then write it during the FIRST run. With
          // synchronous flush this re-enters the callback before `running`
          // is reset → the expect above fails.
          final value = source.value;
          if (runs == 1) {
            source.value = value + 1;
          }

          maxConcurrentDepth--;
          running = false;
        });

        addTearDown(effect.dispose);
        expect(maxConcurrentDepth, 0);
        // The effect re-runs once (sequentially) for the value change.
        expect(runs, 2);
        expect(source.value, 1);
      },
    );

    test(
      '''a late-final read inside the effect survives a write triggered mid-construction''',
      () {
        final previousAutoDispose = SolidartConfig.autoDispose;
        addTearDown(() => SolidartConfig.autoDispose = previousAutoDispose);
        SolidartConfig.autoDispose = false;
        // `dep` mimics a controller built lazily during the effect run whose
        // constructor writes to a collection signal.
        final trigger = Signal(0, name: 'trigger');
        late final int lazy;
        var lazyInitialized = false;

        final effect = Effect(() {
          // Read `trigger` (subscribe). On first run, lazily initialize a
          // value whose initializer writes `trigger` — a synchronous flush
          // would re-enter HERE before `lazy` finishes initializing.
          final t = trigger.value;
          if (!lazyInitialized) {
            lazyInitialized = true;
            // Initializer body writes the signal the effect depends on.
            trigger.value = t + 1;
            lazy = 42;
          }
          // Reading `lazy` must never throw LateInitializationError.
          expect(lazy, 42);
        });

        addTearDown(effect.dispose);
        expect(lazy, 42);
      },
    );
  });
}
