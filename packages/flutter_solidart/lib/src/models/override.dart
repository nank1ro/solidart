// ignore_for_file: prefer_const_constructors_in_immutables

part of '../widgets/provider_scope.dart';

@immutable
sealed class Override {
  Override._();
}

@immutable
class ProviderOverride<T extends Object> extends Override {
  ProviderOverride._(
    this._provider, {
    CreateProviderFn<T>? create,
    DisposeProviderFn<T>? dispose,
    bool? lazy,
  })  : _create = create,
        _dispose = dispose,
        _lazy = lazy,
        super._();

  /// The reference of the provider to override.
  final Provider<T> _provider;

  final CreateProviderFn<T>? _create;

  final DisposeProviderFn<T>? _dispose;

  final bool? _lazy;

  /// Creates a [Provider].
  /// This method is used internally by [ProviderScope].
  Provider<T> _generateProvider() => Provider<T>(
        (context) => _create?.call(context) ?? _provider._create(context),
        dispose: _dispose ?? _provider._dispose,
        lazy: _lazy ?? _provider._lazy,
      );
}

@immutable
class ArgProviderOverride<T extends Object, A> extends Override {
  ArgProviderOverride._(
    this._argProvider, {
    required A argument,
    CreateProviderFnWithArg<T, A>? create,
    DisposeProviderFn<T>? dispose,
    bool? lazy,
  })  : _create = create,
        _argument = argument,
        _dispose = dispose,
        _lazy = lazy,
        super._();

  /// The reference of the argument provider to override.
  final ArgProvider<T, A> _argProvider;

  /// @macro Provider.create}
  final CreateProviderFnWithArg<T, A>? _create;

  final A? _argument;

  final DisposeProviderFn<T>? _dispose;

  final bool? _lazy;

  /// Given an argument, creates a [Provider] with that argument.
  /// This method is used internally by [ProviderScope].
  Provider<T> _generateProvider(A arg) => Provider<T>(
        (context) =>
            _create?.call(context, arg) ?? _argProvider._create(context, arg),
        dispose: _dispose ?? _argProvider._dispose,
        lazy: _lazy ?? _argProvider._lazy,
      );
}
