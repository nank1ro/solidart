import 'package:solidart/devtools.dart';
import 'package:solidart/solidart.dart';

import './main.dart' as s;

final class Logger implements SolidartObserver {
  const Logger();

  @override
  void didCreateSignal(ReadableSignal<Object?> signal) {
    // ignore: avoid_print
    print('Creates a new signal: ${signal.name}, value: ${untrack(signal)}');
  }

  @override
  void didDisposeSignal(ReadableSignal<Object?> signal) {
    // TODO: implement didDisposeSignal
  }

  @override
  void didUpdateSignal(ReadableSignal<Object?> signal) {
    // ignore: avoid_print
    print('Updates a signal: ${signal.name}, value: ${untrack(signal)}');
  }
}

void main() {
  Solidart.dev = true;
  Solidart.observers.add(const Logger());
  s.main();
}
