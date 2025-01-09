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
    this.create, {
    DisposeProviderFn<T>? dispose,
    this.lazy = true,
  }) {
    this.dispose = (provider) {
      dispose?.call(provider);
      _instance = null;
    };
  }

  /// {@macro Provider.lazy}
  final bool lazy;

  /// {@macro Provider.create}
  late final CreateProviderFnWithArg<T, A> create;

  /// {@macro Provider.dispose}
  DisposeProviderFn<T>? dispose;

  Provider<T>? _instance;

  /// Given an argument, creates a [Provider] with that argument.
  Provider<T> call(A arg) {
    _instance ??= Provider<T>(
      (context) => create(context, arg),
      dispose: dispose,
      lazy: lazy,
    );
    return _instance!;
  }

  /// Returns the type of the value
  Type get _valueType => T;

  /// Returns the type of the arg
  Type get _argumentType => A;
}
