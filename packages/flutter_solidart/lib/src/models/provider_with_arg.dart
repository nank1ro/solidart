part of '../widgets/provider_scope.dart';

// ignore: public_member_api_docs
typedef InitProviderValueWithArgFn<A, T> = T Function(A arg);

/// {@template provider-arg}
/// Add docs.
/// {@endtemplate}
// ignore: must_be_immutable
class ProviderWithArg<A, T> extends Provider<T> {
  /// {@macro provider-arg}
  ProviderWithArg(
    InitProviderValueWithArgFn<A, T> init, {
    super.dispose,
    super.lazy,
  })  : _initInternal = init,
        super._withArg() {
    super._init = () {
      if (!_argWasSet) {
        throw SolidartException(
          'Initial argument for this ProviderWithArg missing.',
        );
      }
      return _initInternal(_arg as A);
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

  final InitProviderValueWithArgFn<A, T> _initInternal;
}
