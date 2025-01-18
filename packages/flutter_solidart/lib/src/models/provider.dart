// ignore_for_file: prefer_const_constructors_in_immutables

part of '../widgets/provider_scope.dart';

/// A function that creates an object of type [T].
typedef CreateProviderFn<T> = T Function(BuildContext context);

/// A function that disposes an object of type [T].
typedef DisposeProviderFn<T> = void Function(T value);

/// {@template provider}
/// A Provider that manages the lifecycle of the value it provides by
/// delegating to a pair of [_create] and [_dispose].
///
/// It is usually used to avoid making a StatefulWidget for something trivial,
/// such as instantiating a BLoC.
///
/// Provider is the equivalent of a State.initState combined with State.dispose.
/// [_create] is called only once in State.initState.
/// The `create` callback is lazily called. It is called the first time the
/// value is read, instead of the first time Provider is inserted in the widget
/// tree.
/// This behavior can be disabled by passing [_lazy] false.
///
/// The [_dispose] method will not be called if the provider is a `SignalBase`,
/// because they are disposed automatically when there aren't any subscribers.
///
/// {@endtemplate}
@immutable
class Provider<T extends Object> extends InstantiableProvider {
  //! NB: do not make the constructor `const`, since that would give the same
  //! hash code to different instances of `Provider` with the same generic
  //! type.

  /// {@macro provider}
  Provider(
    /// @macro Provider.create}
    CreateProviderFn<T> create, {
    /// {@macro Provider.dispose}
    DisposeProviderFn<T>? dispose,

    /// {@macro Provider.lazy}
    bool lazy = true,
  })  : _create = create,
        _dispose = dispose,
        _lazy = lazy,
        super._();

  /// {@macro arg-provider}
  static ArgProvider<T, A> withArgument<T extends Object, A>(
    CreateProviderFnWithArg<T, A> create, {
    DisposeProviderFn<T>? dispose,
    bool lazy = true,
  }) =>
      ArgProvider._(create, dispose: dispose, lazy: lazy);

  /// {@template Provider.lazy}
  /// Make the provider creation lazy, defaults to true.
  ///
  /// If this value is true the provider will be [_create]d only
  /// when retrieved from descendants.
  /// {@endtemplate}
  final bool _lazy;

  /// {@template Provider.create}
  /// The function called to create the element.
  /// {@endtemplate}
  final CreateProviderFn<T> _create;

  /// {@template Provider.dispose}
  /// An optional dispose function called when the Solid that created this
  /// provider gets disposed.
  /// {@endtemplate}
  final DisposeProviderFn<T>? _dispose;

  /// Function internally used by [ProviderScopeState] that calls [_dispose].
  void _disposeFn(BuildContext context, dynamic value) {
    _dispose?.call(value as T);
  }

  /// Returns the type of the value

  Type get _valueType => T;

  ProviderOverride<T> overrideWith({
    CreateProviderFn<T>? create,
    DisposeProviderFn<T>? dispose,
    bool? lazy,
  }) =>
      ProviderOverride._(
        this,
        create: create,
        dispose: dispose,
        lazy: lazy,
      );
}
