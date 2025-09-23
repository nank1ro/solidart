import 'package:flutter/widgets.dart';

import '../core/solidart_widget.dart';

class SignalBuilder<T extends Widget> extends SolidartWidget {
  const SignalBuilder({super.key, this.child, required this.builder});

  final Widget? child;
  final T Function(BuildContext context, Widget? child) builder;

  @override
  T build(BuildContext context) => builder(context, child);
}
