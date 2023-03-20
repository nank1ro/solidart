import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

/// A function that creates an object of type [T].
typedef Create<T> = T Function();

/// A function that disposes an object of type [T].
typedef Dispose<T> = void Function(T value);

@immutable
class SolidProvider<T> {
  const SolidProvider({
    required this.create,
    this.dispose,
    this.lazy = true,
  });

  /// The function called to create the provider.
  final Create<T> create;

  /// An optional dispose function called when the Solid that created this
  /// provider disposes
  final Dispose<T>? dispose;

  /// Make the provider creation lazy, defaults to true.
  ///
  /// If this value is true the provider will be [create]d only
  /// when retrieved from descendants.
  final bool lazy;

  @internal
  Type get valueType => T;

  @internal
  void disposeFn(BuildContext context, dynamic value) {
    dispose?.call(value as T);
  }
}
