import 'dart:async';

import 'package:solidart/solidart.dart';

Future<void> main() async {
  final counter = createSignal(0);
  createEffect(
    () {
      // ignore: avoid_print
      print('The counter is now: ${counter.value}');
    },
    signals: [counter],
    fireImmediately: true,
  );

  counter.value++;

  // The signal sets the value asynchronously, so here we await for the value
  // to be notified to listeners.
  await Future<void>.value();

  // dispose the counter;
  counter.dispose();
}
