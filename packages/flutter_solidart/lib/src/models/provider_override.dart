part of '../widgets/provider_scope.dart';

sealed class Override<T> {
  Override._({
    required DisposeProviderFn<T>? dispose,
    required bool? lazy,
  })  : _lazy = lazy,
        _dispose = dispose;

  final DisposeProviderFn<T>? _dispose;

  final bool? _lazy;
}

final class ProviderOverride<T> extends Override<T> {
  ProviderOverride._(
    this._provider, {
    CreateProviderFn<T>? create,
    super.dispose,
    super.lazy,
  })  : _create = create,
        super._();

  /// The reference of the provider to override.
  final Provider<T> _provider;

  final CreateProviderFn<T>? _create;
}

final class ArgProviderOverride<T, A> extends Override<T> {
  ArgProviderOverride._(
    this._argProvider, {
    CreateProviderFnWithArg<T, A>? create,
    A? initialArgument,
    super.dispose,
    super.lazy,
  })  : _create = create,
        _initialArgument = initialArgument,
        super._();

  /// The reference of the argument provider to override.
  final ArgProvider<T, A> _argProvider;

  /// @macro Provider.create}
  final CreateProviderFnWithArg<T, A>? _create;

  final A? _initialArgument;
}
