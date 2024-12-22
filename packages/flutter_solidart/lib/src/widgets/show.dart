import 'package:flutter/material.dart';
import 'package:flutter_solidart/src/widgets/signal_builder.dart';
import 'package:solidart/solidart.dart';

/// {@template show}
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
/// final loggedIn = Signal(false);
///
/// @override
/// Widget build(BuildContext context) {
///   return SignalBuilder(
///     builder: (context, child) {
///       if (loggedIn()) return const Text('Logged in');
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
/// The `Show` widget takes a functions that returns a `bool`.
/// You can easily convert any type to `bool`, for example:
///
/// ```dart
/// final count = Signal(0);
///
/// @override
/// Widget build(BuildContext context) {
///   return Show(
///     when: () => count() > 5,
///     builder: (context) => const Text('Count is greater than 5'),
///     fallback: (context) => const Text('Count is lower than 6'),
///   );
/// }
/// ```
/// {@endtemplate}
class Show<T extends bool> extends StatefulWidget {
  /// {@macro show}
  const Show({
    super.key,
    required this.when,
    required this.builder,
    this.fallback,
  });

  /// A boolean Signal used to determine which builder needs to be used.
  ///
  /// When the Signal's value is true, renders the [builder], otherwise the
  ///  [fallback] (if provided, or an empty view).
  final T Function() when;

  /// The builder widget is rendered when the [when] signal value evalutes to
  /// `true`
  final WidgetBuilder builder;

  /// The fallback widget is rendered when the [when] signal value evalutes to
  /// `false`
  final WidgetBuilder? fallback;

  @override
  State<Show<T>> createState() => _ShowState<T>();
}

class _ShowState<T extends bool> extends State<Show<T>> {
  final show = ValueNotifier(false);
  late final Effect effect;

  @override
  void initState() {
    super.initState();
    effect = Effect((_) {
      show.value = widget.when();
    });
  }

  @override
  void dispose() {
    show.dispose();
    effect.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: show,
      builder: (context, condition, _) {
        if (!condition) {
          return widget.fallback?.call(context) ?? const SizedBox.shrink();
        }
        return widget.builder(context);
      },
    );
  }
}
