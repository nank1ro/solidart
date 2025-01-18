part of '../widgets/provider_scope.dart';

sealed class Override<T extends Object> {
  Override._({
    required DisposeProviderFn<T>? dispose,
    required bool? lazy,
  })  : _lazy = lazy,
        _dispose = dispose;

  final DisposeProviderFn<T>? _dispose;

  final bool? _lazy;
}

final class ProviderOverride<T extends Object> extends Override<T> {
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

  /// Creates a [Provider].
  /// This method is used internally by [ProviderScope].
  Provider<T> _generateProvider() => Provider<T>(
        (context) => _create?.call(context) ?? _provider._create(context),
        dispose: _dispose ?? _provider._dispose,
        lazy: _lazy ?? _provider._lazy,
      );
}

final class ArgProviderOverride<T extends Object, A> extends Override<T> {
  ArgProviderOverride._(
    this._argProvider, {
    required A argument,
    CreateProviderFnWithArg<T, A>? create,
    super.dispose,
    super.lazy,
  })  : _create = create,
        _argument = argument,
        super._();

  /// The reference of the argument provider to override.
  final ArgProvider<T, A> _argProvider;

  /// @macro Provider.create}
  final CreateProviderFnWithArg<T, A>? _create;

  final A? _argument;

  /// Given an argument, creates a [Provider] with that argument.
  /// This method is used internally by [ProviderScope].
  Provider<T> _generateProvider(A arg) => Provider<T>(
        (context) =>
            _create?.call(context, arg) ?? _argProvider._create(context, arg),
        dispose: _dispose ?? _argProvider._dispose,
        lazy: _lazy ?? _argProvider._lazy,
      );
}
