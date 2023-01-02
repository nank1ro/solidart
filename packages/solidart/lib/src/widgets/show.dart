import 'package:flutter/material.dart';
import 'package:solidart/src/core/signal.dart';
import 'package:solidart/src/widgets/signal_builder.dart';

/// Conditionally render its [builder] or an optional [fallback] component
/// based on the [when] evaluation.
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
