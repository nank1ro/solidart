import 'dart:async';

import 'package:solidart/solidart.dart';

Future<void> main() async {
  // final obs = createSignalN(0);
  // final disposer = createEffectN(() {
  //   print('The counter is now ${obs.value}');
  // });
  //
  // final double = createComputed(() => obs.value * 2);
  // print("double: ${double.value}");
  //
  // obs.value = 1;
  // print(obs.value);
  // print("double: ${double.value}");
  //
  // obs.value = 2;
  // print(obs.value);
  // print("double: ${double.value}");
  final counter = createSignal(0);

// Automatically updates when `counter` changes:
  // final isEven = createComputed(() => counter().isEven);
  // print(isEven);

  final double = createComputed(() => counter() * 2);
  // double.observe((previousValue, value) {
  //   print('previousValue: $previousValue, value: $value');
  // }, fireImmediately: false);
  final effect = createEffect(() {
    print('The counter is now ${counter.value}');
    print('The double-counter is now ${double.value}');
  });

  // print(counter());
  counter.value = 1;
  // print(counter());
  // print(isEven);
  counter.update((count) => count + 1);
  // print(counter());
  // print(isEven);
}
