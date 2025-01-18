import 'package:reactivity_benchmark/reactive_framework.dart';
import 'package:reactivity_benchmark/run_framework_bench.dart';
import 'package:reactivity_benchmark/utils/create_computed.dart';
import 'package:reactivity_benchmark/utils/create_signal.dart';
import 'package:solidart/solidart.dart' as solidart;

final class SolidartReactiveFramework extends ReactiveFramework {
  const SolidartReactiveFramework() : super('solidart');

  @override
  Computed<T> computed<T>(T Function() fn) {
    final computed = solidart.Computed<T>(fn);
    return createComputed(computed);
  }

  @override
  void effect(void Function() fn) {
    solidart.Effect((_) => fn());
  }

  @override
  Signal<T> signal<T>(T value) {
    final signal = solidart.Signal(value);
    return createSignal(signal, signal.set);
  }

  @override
  void withBatch<T>(T Function() fn) {
    solidart.system.startBatch();
    fn();
    solidart.system.endBatch();
  }

  @override
  T withBuild<T>(T Function() fn) {
    return fn();
  }
}

void main() {
  const framework = SolidartReactiveFramework();
  runFrameworkBench(framework);
}
