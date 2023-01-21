import 'package:solidart/solidart.dart';

Future<void> main() async {
  final counter = createSignal(0);
  createEffect(
    () {
      print("The counter is now: ${counter.value}");
    },
    signals: [counter],
    fireImmediately: true,
  );

  counter.value++;

  // The signal sets the value asynchronously, so here we await for the value
  // to be notified to listeners.
  await Future.value();

  // dispose the counter;
  counter.dispose();
}
