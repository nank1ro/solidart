import 'package:flutter/foundation.dart';
import 'package:flutter_solidart/src/core/value_listenable_signal_mixin.dart';
import 'package:solidart/solidart.dart' as core;

/// A Solidart [core.Computed] that is also a Flutter [ValueListenable].
class Computed<T> extends core.Computed<T> with SignalValueListenableMixin<T> {
  /// Creates a new [Computed] and exposes it as a [ValueListenable].
  Computed(
    super.getter, {
    super.equals,
    super.autoDispose,
    super.name,
    super.trackPreviousValue,
    super.trackInDevTools,
  });
}
