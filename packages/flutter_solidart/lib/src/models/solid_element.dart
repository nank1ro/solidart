part of '../widgets/solid.dart';

/// A function that creates an object of type [T].
typedef Create<T> = T Function();

/// A function that disposes an object of type [T].
typedef DisposeValue<T> = void Function(T value);

/// The idenfifier of the element.
typedef Identifier = Object;

/// {@template solidelement}
/// The base class of a solid provider
/// {@endtemplate}
abstract class SolidElement<T> {
  /// {@macro solidelement}
  const SolidElement({
    required this.create,
    this.id,
  });

  /// The function called to create the element.
  final Create<T> create;

  /// The identifier of the provider, useful to distinguish between providers
  /// with the same Type.
  final Identifier? id;

  /// Returns the type of the value
  Type get _valueType => T;

  bool get _isSignal => this is SolidElement<ReadableSignal>;

  void _disposeFn(BuildContext context, dynamic value);
}

// coverage:ignore-start
/// {@macro provider}
@Deprecated('Use Provider instead')
typedef SolidProvider<T> = Provider<T>;
// coverage:ignore-end

/// {@template provider}
/// A Provider that manages the lifecycle of the value it provides by
// delegating to a pair of [create] and [dispose].
///
/// It is usually used to avoid making a StatefulWidget for something trivial,
/// such as instantiating a BLoC.
///
/// Provider is the equivalent of a State.initState combined with State.dispose.
/// [create] is called only once in State.initState.
/// The `create` callback is lazily called. It is called the first time the
/// value is read, instead of the first time Provider is inserted in the widget
/// tree.
/// This behavior can be disabled by passing [lazy] false.
///
/// You can pass an optional [id] to have multiple providers of the same type.
///
/// The [dispose] method will not be called if the provider is a `SignalBase`,
/// because they are disposed automatically when there aren't any subscribers.
///
/// {@endtemplate}
@immutable
class Provider<T> extends SolidElement<T> {
  /// {@macro provider}
  const Provider({
    required super.create,
    this.dispose,
    this.lazy = true,
    super.id,
  });

  /// An optional dispose function called when the Solid that created this
  /// provider disposes
  final DisposeValue<T>? dispose;

  /// Make the provider creation lazy, defaults to true.
  ///
  /// If this value is true the provider will be [create]d only
  /// when retrieved from descendants.
  final bool lazy;

  /// Dispose function, do not use.
  @override
  void _disposeFn(BuildContext context, dynamic value) {
    dispose?.call(value as T);
  }
}
