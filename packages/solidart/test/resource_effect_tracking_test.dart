import 'dart:async';

import 'package:solidart/solidart.dart';
import 'package:test/test.dart';

Future<void> settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  group('Resource does not track the caller effect while resolving', () {
    test(
      'a lazy fetcher read inside an effect does not depend on the signals '
      'it reads',
      () async {
        final account = Signal(1, autoDispose: true);
        final pending = Completer<int>();
        // Lazy (the default): the fetcher runs on the first read of `state`.
        final user = Resource<int>(() {
          account.value; // the fetcher reads another signal
          return pending.future;
        });

        var calls = 0;
        final stop = user.observe((_, _) => calls++);

        // The fetcher's read of `account` must not subscribe the caller effect.
        expect(account.listenerCount, 0);

        // The resource has no source, so changing `account` must not refetch
        // it nor notify the observer.
        account.value = 2;
        expect(calls, 0);

        stop();
        pending.complete(1);
      },
    );

    test(
      'a stream resource with a source keeps following the source after the '
      'first event when first read inside an effect',
      () async {
        final source = Signal(0);
        var streams = 0;
        final r = Resource<int>.stream(() {
          streams++;
          return Stream.value(source.untrackedValue * 10);
        }, source: source);

        // First read happens inside an effect.
        final stop = r.observe((_, _) {});

        expect(source.listenerCount, 1);
        await settle();
        // The source observation must survive the first stream event.
        expect(source.listenerCount, 1);

        source.value = 1;
        await settle();
        // The source change must resubscribe the stream and update the state.
        expect(streams, 2);
        expect(r.untrackedState, isA<ResourceReady<int>>());
        expect((r.untrackedState as ResourceReady<int>).value, 10);

        stop();
      },
    );
  });
}
