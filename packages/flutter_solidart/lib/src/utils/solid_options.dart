import 'package:flutter/foundation.dart';
import 'package:solidart/solidart.dart';

/// {@template solid-signal-options}
/// Additional options for signals provided through the Solid widget
/// {@endtemplate}
@immutable
class SolidSignalOptions<T> extends SignalOptions<T> {
  /// {@macro solid-signal-options}
  const SolidSignalOptions({
    super.name,
    super.equals,
    super.comparator,
    this.autoDispose = true,
  });

  /// Indicates whether the signal should auto dispose
  /// when the Solid widget disposes, defaults to true.
  final bool autoDispose;
}

/// {@template solid-resource-options}
/// Additional options for resources provided through the Solid widget
/// {@endtemplate}
@immutable
class SolidResourceOptions extends ResourceOptions {
  /// {@macro solid-resource-options}
  const SolidResourceOptions({
    super.name,
    super.lazy,
    this.autoDispose = true,
  });

  /// Indicates whether the resource should auto dispose
  /// when the Solid widget disposes, defaults to true.
  final bool autoDispose;
}
