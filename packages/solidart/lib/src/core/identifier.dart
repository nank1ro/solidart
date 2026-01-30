part of '../solidart.dart';

/// A unique identifier with an optional name.
///
/// Used by DevTools and diagnostics to track instances.
class Identifier {
  Identifier._(this.name) : value = _counter++;
  static int _counter = 0;

  /// Optional human-readable name.
  final String? name;

  /// Unique numeric identifier.
  final int value;
}
