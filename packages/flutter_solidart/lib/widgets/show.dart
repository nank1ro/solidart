import 'package:flutter/material.dart';
import 'package:flutter_solidart/widgets/signal_builder.dart';
import 'package:solidart/solidart.dart';

/// Conditionally render its [builder] or an optional [fallback] component
/// based on the [when] evaluation.
///
/// You should typically find yourself in the condition of wanting to render
/// one widget or another based on the state of a signal.
///
/// Let's look at a simple example where we show the text 'Logged In' if the
/// user is logged in or 'Logged out'.
///
/// ```dart
/// // sample signal that tells if the user is logged in or not
/// final loggedIn = createSignal(false);
///
/// @override
/// Widget build(BuildContext context) {
///   return SignalBuilder(
///     signal: loggedIn,
///     builder: (context, isUserLoggedIn, child) {
///       if (isUserLoggedIn) return const Text('Logged in');
///       return const Text('Logged out');
///     },
///   );
/// }
/// ```
///
/// You may be tempted to use a [SignalBuilder] but with the `Show` widget is
/// even simpler:
///
/// ```dart
/// @override
/// Widget build(BuildContext context) {
///   return Show(
///     when: loggedIn,
///     builder: (context) => const Text('Logged In'),
///     fallback: (context) => const Text('Logged out'),
///   );
/// }
/// ```
///
/// The `Show` widget conditionally renders its `builder` or the `fallback`
/// widget based on the `when` evaluation.
/// The `fallback` widget builder is optional, by default nothing is rendered.
///
/// The `Show` widget takes a `Signal` of type `bool`, see [Derived Signals](/learning/derived-signals) to learn how to create a derived signal if your Signal is not of type `bool`.
class Show<T extends bool> extends StatelessWidget {
  const Show({
    super.key,
    required this.when,
    required this.builder,
    this.fallback,
  });

  final Signal<T> when;
  final WidgetBuilder? fallback;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return SignalBuilder<T>(
      signal: when,
      builder: (context, condition, _) {
        if (!condition) {
          return fallback?.call(context) ?? const SizedBox();
        }
        return builder(context);
      },
    );
  }
}
