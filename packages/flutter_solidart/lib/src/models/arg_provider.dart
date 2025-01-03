part of '../widgets/provider_scope.dart';

// ignore: public_member_api_docs
typedef CreateProviderFnWithArg<A, T> = T Function(A arg);

/// {@template arg-provider}
/// A [Provider] that needs to be given an initial argument before
/// it can be used. If this condition is not met, a
/// [MissingProviderInitialArgument] will be thrown at runtime.
/// {@endtemplate}
// ignore: must_be_immutable
class ArgProvider<A, T> extends Provider<T> {
  /// {@macro arg-provider}
  ArgProvider(
    CreateProviderFnWithArg<A, T> create, {
    super.dispose,
    super.lazy,
    super.debugName,
  })  : _createInternal = create,
        super._withArg() {
    // set the _create member now (can't be done in the initializer list
    // since _arg cannot be accessed from there yet).
    super._create = () {
      if (!_argWasSet) {
        throw MissingProviderInitialArgument<T>(this);
      }
      return _createInternal(_arg as A);
    };
  }

  /// Does not necessarily have to be used inside the [ProviderScope.providers].
  /// The initial argument can be set above or below it. The only requirement is
  /// that it is set before being consumed.
  ///
  /// The initial argument can be overridden. However, only the value present
  /// during creation of the provider will be used. Successive overrides will
  /// not have any meaningful effect as long as the provider is within
  /// [ProviderScope].
  void setInitialArg(A arg) {
    _arg = arg;
    _argWasSet = true;
  }

  bool _argWasSet = false;
  A? _arg;

  final CreateProviderFnWithArg<A, T> _createInternal;
}

/// {@template MissingProviderInitialArgument}
/// Error thrown when the provider is being created but no initial value was
/// set.
/// {@endtemplate}
class MissingProviderInitialArgument<T> extends Error {
  /// {@macro MissingProviderInitialArgument}
  MissingProviderInitialArgument(this.argProvider);

  // ignore: public_member_api_docs
  final ArgProvider<dynamic, T> argProvider;

  @override
  String toString() {
    return '''
      Initial argument for this ArgProvider missing.
      Provider type: ${argProvider._valueType}
      Provider debug name: ${argProvider._debugName == null ? "not assigned" : argProvider._debugName!}
      ''';
  }
}
