part of '../widgets/provider_scope.dart';

/// A function that creates an object of type [T].
typedef CreateProviderFn<T> = T Function();

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
/// This behavior can be disabled by passing [lazy] false.
///
/// The [_dispose] method will not be called if the provider is a `SignalBase`,
/// because they are disposed automatically when there aren't any subscribers.
///
/// {@endtemplate}
@immutable
class Provider<T> {
  //! NB: do not make the constructor `const`, since that would give the same
  //! hash code to different instances of `Provider` with the same generic
  //! type.

  /// {@macro provider}
  // ignore: prefer_const_constructors_in_immutables
  Provider(
    CreateProviderFn<T> create, {
    DisposeProviderFn<T>? dispose,
    this.lazy = true,
    String? debugName,
  })  : _create = create,
        _dispose = dispose,
        _debugName = debugName;

  /// This constructor purposely leaves out [_create]. This way
  /// [ArgProvider._] can leverage the [ArgProvider._arg] member
  /// when instantiating [_create].
  // ignore: prefer_const_constructors_in_immutables
  Provider._withArg({
    DisposeProviderFn<T>? dispose,
    this.lazy = true,
    String? debugName,
  })  : _dispose = dispose,
        _debugName = debugName;

  /// {@macro arg-provider}
  static ArgProvider<A, T> withArg<A, T>(
    CreateProviderFnWithArg<A, T> create, {
    DisposeProviderFn<T>? dispose,
    bool lazy = true,
    String? debugName,
  }) =>
      ArgProvider._(create, dispose: dispose, debugName: debugName, lazy: lazy);

  /// Make the provider creation lazy, defaults to true.
  ///
  /// If this value is true the provider will be [_create]d only
  /// when retrieved from descendants.
  final bool lazy;

  bool get _isSignal => this is Provider<SignalBase>;

  /// The function called to create the element.
  late final CreateProviderFn<T> _create;

  /// An optional dispose function called when the Solid that created this
  /// provider gets disposed.
  final DisposeProviderFn<T>? _dispose;

  /// Function internally used by [ProviderScopeState] that calls [_dispose].
  void _disposeFn(BuildContext context, dynamic value) {
    _dispose?.call(value as T);
  }

  /// This is a bit of a hack: it is used in [ProviderScope.value] and
  /// [ProviderScope.values].
  /// If [ProviderScope._getProvider] were used directly by the two
  /// constructors, the type will be wrongly inferred to `dynamic` instead
  /// of the precise type, and it would result in runtime exception.
  Provider<T> _getProvider(
    BuildContext context,
  ) {
    return ProviderScope._getProvider<T>(context, this);
  }

  /// Returns the type of the value
  Type get _valueType => T;

  /// Acts as an identifier. If set, it simplifies tracking down the provider
  /// causing an exception.
  final String? _debugName;
}
