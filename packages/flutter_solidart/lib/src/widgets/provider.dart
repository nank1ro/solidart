import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

/// A function that creates an object of type [T].
typedef Create<T> = T Function(BuildContext context);

/// A function that disposes an object of type [T].
typedef Dispose<T> = void Function(BuildContext context, T value);

@immutable
class SolidProvider<T> {
  const SolidProvider({
    required this.create,
    this.onDispose,
    this.lazy = true,
  });

  /// The function called to create the provider.
  final Create<T> create;

  /// An optional dispose function called when the Solid that created this
  /// provider disposes
  final Dispose<T>? onDispose;

  /// Make the provider creation lazy, defaults to true.
  ///
  /// If this value is true the provider will be [create]d only
  /// when retrieved from descendants.
  final bool lazy;

  @internal
  Type get type => T;

  @internal
  void dispose(BuildContext context, dynamic value) {
    onDispose?.call(context, value as T);
  }
}
