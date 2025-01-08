part of '../widgets/provider_scope.dart';

// ignore: public_member_api_docs
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
      instances.clear();
    };
  }

  /// {@macro Provider.lazy}
  final bool lazy;

  /// {@macro Provider.create}
  late final CreateProviderFnWithArg<T, A> create;

  /// {@macro Provider.dispose}
  DisposeProviderFn<T>? dispose;

  final instances = <Type, Provider<T>>{};

  Provider<T> call(A arg) {
    if (instances.containsKey(A)) {
      return instances[A]!;
    }
    final instance = Provider<T>(
      (context) => create(context, arg),
      dispose: dispose,
      lazy: lazy,
    );
    instances[A] = instance;
    return instance;
  }
}
