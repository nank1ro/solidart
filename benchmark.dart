import 'package:reactivity_benchmark/reactive_framework.dart';
import 'package:reactivity_benchmark/run_framework_bench.dart';
import 'package:reactivity_benchmark/utils/create_computed.dart';
import 'package:reactivity_benchmark/utils/create_signal.dart';
import 'package:solidart/solidart.dart' as solidart;

class SolidartReactiveFramework extends ReactiveFramework {
  const SolidartReactiveFramework() : super('solidart');

  @override
  Computed<T> computed<T>(T Function() fn) {
    final computed = solidart.Computed(fn);
    return createComputed(computed.call);
  }

  @override
  void effect(void Function() fn) {
    solidart.Effect(() => fn());
  }

  @override
  Signal<T> signal<T>(T value) {
    final signal = solidart.Signal(value);
    return createSignal(signal.call, signal.set);
  }

  @override
  void withBatch<T>(T Function() fn) {
    solidart.batch(fn);
  }

  @override
  T withBuild<T>(T Function() fn) {
    return fn();
  }
}

void main() {
  solidart.SolidartConfig.devToolsEnabled = false;
  solidart.SolidartConfig.trackPreviousValue = false;
  solidart.SolidartConfig.equals = true;
  const framework = SolidartReactiveFramework();
  runFrameworkBench(framework);
}
