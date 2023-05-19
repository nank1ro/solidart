import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

/// A function that creates an object of type [T].
typedef Create<T> = T Function();

/// A function that disposes an object of type [T].
typedef DisposeValue<T> = void Function(T value);

/// {@template solidprovider}
/// A Provider that manages the lifecycle of the value it provides by
// delegating to a pair of `create` and `dispose`.
///
/// It is usually used to avoid making a StatefulWidget for something trivial,
/// such as instantiating a BLoC.
///
/// Provider is the equivalent of a State.initState combined with State.dispose.
/// `create` is called only once in State.initState.
/// The `create` callback is lazily called. It is called the first time the
/// value is read, instead of the first time Provider is inserted in the widget
/// tree.
/// This behavior can be disabled by passing lazy: false to Provider.
/// {@endtemplate}
@immutable
class SolidProvider<T> {
  /// {@macro solidprovider}
  const SolidProvider({
    required this.create,
    this.dispose,
    this.lazy = true,
  });

  /// The function called to create the provider.
  final Create<T> create;

  /// An optional dispose function called when the Solid that created this
  /// provider disposes
  final DisposeValue<T>? dispose;

  /// Make the provider creation lazy, defaults to true.
  ///
  /// If this value is true the provider will be [create]d only
  /// when retrieved from descendants.
  final bool lazy;

  /// Returns the type of the value, do not use.
  @protected
  Type get valueType => T;

  /// Dispose function, do no use.
  @protected
  void disposeFn(BuildContext context, dynamic value) {
    dispose?.call(value as T);
  }
}
