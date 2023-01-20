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

  Future<int> fetcher() => Future.value(1);
  final resource = createResource(fetcher: fetcher);

  createEffect(() {
    resource.value.on(
      ready: (r, refreshing) => print('ready $r'),
      error: (e, stackTrace) => print('Error: $e'),
      loading: () => print('loading'),
    );
  }, signals: [resource]);

  resource.fetch();
}
