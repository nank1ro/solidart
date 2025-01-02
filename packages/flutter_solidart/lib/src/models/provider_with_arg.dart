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

  /// Does not necessarily have to be placed inside the ProviderScope widget.
  /// The initial arg can be set above or below it, as long as it is
  void setInitialArg(A arg) {
    assert(
      _argWasSet == false,
      'Initial argument of this ProviderWithArg was already set.',
    );
    _arg = arg;
    _argWasSet = true;
  }

  bool _argWasSet = false;
  A? _arg;

  final InitProviderValueWithArgFn<A, T> _initInternal;
}
