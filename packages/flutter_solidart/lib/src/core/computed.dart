import 'package:flutter_solidart/src/core/signal.dart' show ReadonlySignal;
import 'package:flutter_solidart/src/core/value_listenable_signal_mixin.dart';
import 'package:solidart/solidart.dart' as core;

class Computed<T> extends core.Computed<T>
    with SignalValueListenableMixin<T>
    implements ReadonlySignal<T> {
  Computed(
    super.getter, {
    super.equals,
    super.autoDispose,
    super.name,
    super.trackPreviousValue,
    super.trackInDevTools,
  });
}
