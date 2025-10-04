// ignore_for_file: public_member_api_docs

import 'package:solidart/src/signal.dart';

extension SolidartSignalCall<T> on ReadonlySignal<T> {
  T call() => value;
}

extension BooleanSignalOpers on Signal<bool> {
  void toggle() => value = !value;
}
