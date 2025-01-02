part of '../widgets/provider_scope.dart';

/// A function that creates an object of type [T].
typedef InitProviderValueFn<T> = T Function();

/// A function that disposes an object of type [T].
typedef DisposeProviderValueFn<T> = void Function(T value);

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
class Provider<T> {
  //! NB: do not make the constructor `const`, since that would give the same
  //! hash code to different instances of `Provider` with the same generic
  //! type.

  /// {@macro provider}
  // ignore: prefer_const_constructors_in_immutables
  Provider(
    InitProviderValueFn<T> init, {
    DisposeProviderValueFn<T>? dispose,
    this.lazy = true,
  })  : _init = init,
        _dispose = dispose;

  /// This constructor purposely leaves out [_init]. This way
  /// [ProviderWithArg.new] can leverage the [ProviderWithArg._arg] member
  /// when setting [_init].
  // ignore: prefer_const_constructors_in_immutables
  Provider._withArg({
    DisposeProviderValueFn<T>? dispose,
    this.lazy = true,
  }) : _dispose = dispose;

  /// Make the provider creation lazy, defaults to true.
  ///
  /// If this value is true the provider will be [_init]d only
  /// when retrieved from descendants.
  final bool lazy;

  bool get _isSignal => this is Provider<SignalBase>;

  /// The function called to create the element.
  late final InitProviderValueFn<T> _init;

  /// An optional dispose function called when the Solid that created this
  /// provider gets disposed.
  final DisposeProviderValueFn<T>? _dispose;

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
}
