import 'package:awesome_flutter_extensions/awesome_flutter_extensions.dart';
import 'package:flutter/material.dart';

class BasicBadge extends StatelessWidget {
  const BasicBadge({
    super.key,
    required this.label,
    this.color,
    this.leading,
  });

  final String label;
  final Color? color;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final primary = color ?? context.colors.primary;
    final secondary = primary.withAlpha(30);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      decoration: BoxDecoration(
        color: secondary,
        borderRadius: const BorderRadius.all(
          Radius.circular(20),
        ),
        border: Border.all(
          color: primary,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: leading!,
            ),
          Text(
            label,
            style: context.textStyles.bodySmall.copyWith(color: primary),
          ),
        ],
      ),
    );
  }
}
