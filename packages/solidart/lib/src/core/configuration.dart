part of '../solidart.dart';

/// Base configuration shared by reactive primitives.
abstract interface class Configuration {
  /// Whether the instance auto-disposes.
  bool get autoDispose;

  /// Identifier for the instance.
  Identifier get identifier;
}
