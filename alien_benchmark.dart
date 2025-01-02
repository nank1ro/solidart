import 'package:reactivity_benchmark/reactive_framework.dart';
import 'package:reactivity_benchmark/run_framework_bench.dart';
import 'package:reactivity_benchmark/utils/create_computed.dart';
import 'package:reactivity_benchmark/utils/create_signal.dart';
import 'package:alien_signals/alien_signals.dart' as alien;

class AlienReactiveFramework extends ReactiveFramework {
  const AlienReactiveFramework() : super('alien_signals');

  @override
  Computed<T> computed<T>(T Function() fn) {
    final computed = alien.computed<T>((_) => fn());
    return createComputed(computed.get);
  }

  @override
  void effect(void Function() fn) {
    alien.effect(fn);
  }

  @override
  Signal<T> signal<T>(T value) {
    final inner = alien.signal(value);
    return createSignal(inner.get, inner.set);
  }

  @override
  void withBatch<T>(T Function() fn) {
    alien.startBatch();
    fn();
    alien.endBatch();
  }

  @override
  T withBuild<T>(T Function() fn) => fn();
}

void main() {
  const framework = AlienReactiveFramework();
  runFrameworkBench(framework);
}
