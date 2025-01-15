part of '../widgets/provider_scope.dart';

/// A function that creates an object of type [T] with an argument of type [A].
typedef CreateProviderFnWithArg<T, A> = T Function(BuildContext context, A arg);

/// {@template arg-provider}
/// A [Provider] that needs to be given an initial argument before
/// it can be used.
/// {@endtemplate}
// ignore: must_be_immutable
class ArgProvider<T, A> {
  /// {@macro arg-provider}
  ArgProvider._(
    CreateProviderFnWithArg<T, A> create, {
    DisposeProviderFn<T>? dispose,
    bool lazy = true,
  })  : _create = create,
        _lazy = lazy {
    this._dispose = (provider) {
      dispose?.call(provider);
      _instance = null;
    };
  }

  /// {@macro Provider.lazy}
  final bool _lazy;

  /// {@macro Provider.create}
  final CreateProviderFnWithArg<T, A> _create;

  /// {@macro Provider.dispose}
  DisposeProviderFn<T>? _dispose;

  Provider<T>? _instance;

  /// Given an argument, creates a [Provider] with that argument.
  Provider<T> call(A arg) {
    _instance ??= Provider<T>(
      (context) => _create(context, arg),
      dispose: _dispose,
      lazy: _lazy,
    );
    return _instance!;
  }

  /// Returns the type of the value
  Type get _valueType => T;

  /// Returns the type of the arg
  Type get _argumentType => A;

  ArgProviderOverride<T, A> overrideWith({
    CreateProviderFnWithArg<T, A>? create,
    A? initialArgument,
    DisposeProviderFn<T>? dispose,
    bool? lazy,
  }) =>
      ArgProviderOverride._(
        this,
        create: create,
        dispose: dispose,
        initialArgument: initialArgument,
        lazy: lazy,
      );
}
