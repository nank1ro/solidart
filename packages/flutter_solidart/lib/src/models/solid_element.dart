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

  bool get _isSignal => this is SolidElement<SignalBase>;

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
/// The [autoDispose] parameter specifies if the provider should be disposed
/// automatically when the widget is disposed. Defaults to true.
///
/// The [dispose] method will not be called if the provider is a Signal, instead
/// the Signal will be auto-disposed if [autoDispose] is true.
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
    this.autoDispose = true,
  });

  /// An optional dispose function called when the Solid that created this
  /// provider disposes
  final DisposeValue<T>? dispose;

  /// Make the provider creation lazy, defaults to true.
  ///
  /// If this value is true the provider will be [create]d only
  /// when retrieved from descendants.
  final bool lazy;

  /// Whether to auto dispose the provider, defaults to true.
  final bool autoDispose;

  /// Dispose function, do not use.
  @override
  void _disposeFn(BuildContext context, dynamic value) {
    if (!autoDispose) return;
    if (_isSignal) {
      (value as SignalBase).dispose();
    } else {
      dispose?.call(value as T);
    }
  }
}
