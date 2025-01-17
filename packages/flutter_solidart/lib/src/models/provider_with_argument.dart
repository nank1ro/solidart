part of '../widgets/provider_scope.dart';

/// A function that creates an object of type [T] with an argument of type [A].
typedef CreateProviderFnWithArg<T, A> = T Function(BuildContext context, A arg);

/// {@template arg-provider}
/// A [Provider] that needs to be given an initial argument before
/// it can be used.
/// {@endtemplate}
class ArgProvider<T, A> {
  /// {@macro arg-provider}
  ArgProvider._(
    CreateProviderFnWithArg<T, A> create, {
    DisposeProviderFn<T>? dispose,
    bool lazy = true,
  })  : _create = create,
        _lazy = lazy,
        _dispose = dispose;

  /// {@macro Provider.lazy}
  final bool _lazy;

  /// {@macro Provider.create}
  final CreateProviderFnWithArg<T, A> _create;

  /// {@macro Provider.dispose}
  final DisposeProviderFn<T>? _dispose;

  /// Returns the type of the value
  Type get _valueType => T;

  /// Returns the type of the arg
  Type get _argumentType => A;

  /// Given an argument, creates a [Provider] with that argument.
  ArgProviderInit<T, A> call(A arg) {
    return ArgProviderInit._(this, arg);
  }

  /// Given an argument, creates a [Provider] with that argument.
  /// This method is used internally by [ProviderScope].
  Provider<T> _generateProvider(A arg) => Provider<T>(
        (context) => _create(context, arg),
        dispose: _dispose,
        lazy: _lazy,
      );
}

/// {@template arg-provider}
///
/// {@endtemplate}
class ArgProviderInit<T, A> implements InstantiableProvider {
  /// {@macro arg-provider}
  ArgProviderInit._(this._argProvider, this._arg);
  final ArgProvider<T, A> _argProvider;
  final A _arg;
}
