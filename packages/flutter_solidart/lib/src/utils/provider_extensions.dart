import 'package:flutter/widgets.dart' show BuildContext;
import 'package:flutter_solidart/flutter_solidart.dart';

/// Get the value of a provider.
extension InjectExtensionProviderId<T> on Provider<T> {
  /// {@macro provider-scope.get}
  T get(BuildContext context) {
    return ProviderScope.get(context, this);
  }

  /// {@macro provider-scope.maybeGet}
  T? maybeGet(BuildContext context) {
    return ProviderScope.maybeGet(context, this);
  }
}

/// Get the value of a provider.
extension InjectExtensionArgProvider<T, A> on ArgProvider<T, A> {
  /// {@macro provider-scope.get}
  T get(BuildContext context) {
    final instance = instances[A];
    assert(instance != null, 'Provider has not been initialized');
    return ProviderScope.get(context, instance!);
  }

  /// {@macro provider-scope.maybeGet}
  T? maybeGet(BuildContext context) {
    final instance = instances[A];
    assert(instance != null, 'Provider has not been initialized');
    return ProviderScope.maybeGet(context, instance!);
  }
}

/// Observe the value of a [SignalBase] that is in a provider.
extension ObserveExtensionProviderId<T extends SignalBase<dynamic>>
    on Provider<T> {
  /// {@macro provider-scope.observe}
  T observe(BuildContext context) {
    return ProviderScope.observe<T>(context, this);
  }
}

/// Observe the value of a [Signal] that is in a provider.
extension UpdateExtensionProviderId<T> on Provider<Signal<T>> {
  /// {@macro provider-scope.update}
  void update(BuildContext context, T Function(T value) callback) {
    return ProviderScope.update<T>(context, callback, this);
  }
}
