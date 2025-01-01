part of '../widgets/solid.dart';

/// A function that creates an object of type [T].
typedef InitProviderValueFn<T> = T Function();

/// A function that disposes an object of type [T].
typedef DisposeProviderValueFn<T> = void Function(T value);

/// {@template provider-element}
/// The base class of a solid provider
/// {@endtemplate}
abstract class ProviderElement<T> {
  /// {@macro provider-element}
  const ProviderElement._({
    required InitProviderValueFn<T> init,
    required this.id,
  }) : _init = init;

  /// The function called to create the element.
  final InitProviderValueFn<T> _init;

  /// The identifier of the provider, useful to distinguish between providers
  /// with the same Type.
  final ProviderId<T> id;

  bool get _isSignal => this is ProviderElement<SignalBase>;

  void _disposeFn(BuildContext context, dynamic value);
}

// coverage:ignore-start
/// {@macro provider}
@Deprecated('Use Provider instead')
typedef SolidProvider<T> = Provider<T>;
// coverage:ignore-end

/// {@template provider}
/// A Provider that manages the lifecycle of the value it provides by
/// delegating to a pair of [_init] and [_dispose].
///
/// It is usually used to avoid making a StatefulWidget for something trivial,
/// such as instantiating a BLoC.
///
/// Provider is the equivalent of a State.initState combined with State.dispose.
/// [_init] is called only once in State.initState.
/// The `create` callback is lazily called. It is called the first time the
/// value is read, instead of the first time Provider is inserted in the widget
/// tree.
/// This behavior can be disabled by passing [lazy] false.
///
/// You can pass an optional [id] to have multiple providers of the same type.
///
/// The [_dispose] method will not be called if the provider is a `SignalBase`,
/// because they are disposed automatically when there aren't any subscribers.
///
/// {@endtemplate}
@immutable
class Provider<T> extends ProviderElement<T> {
  /// {@macro provider}
  const Provider._(
    ProviderId<T> id, {
    required super.init,
    DisposeProviderValueFn<T>? dispose,
    this.lazy = true,
  })  : _dispose = dispose,
        super._(id: id);

  /// An optional dispose function called when the Solid that created this
  /// provider disposes
  final DisposeProviderValueFn<T>? _dispose;

  /// Make the provider creation lazy, defaults to true.
  ///
  /// If this value is true the provider will be [_init]d only
  /// when retrieved from descendants.
  final bool lazy;

  /// Dispose function, do not use.
  @override
  void _disposeFn(BuildContext context, dynamic value) {
    _dispose?.call(value as T);
  }
}
