import 'package:awesome_flutter_extensions/awesome_flutter_extensions.dart';
import 'package:flutter/material.dart';

class TagBadge extends StatelessWidget {
  const TagBadge({
    super.key,
    required this.name,
    required this.values,
  });

  final String name;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: context.colors.scheme.secondary),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            name.toUpperCase(),
            style: context.textStyles.bodySmall.semiBold.copyWith(
              color: context.colors.primary,
            ),
          ),
          SizedBox(
            height: 26,
            child: VerticalDivider(
              color: context.colors.scheme.tertiary,
            ),
          ),
          ...values.map(
            (v) => Text(
              v.toUpperCase(),
              style: context.textStyles.bodySmall.regular.copyWith(
                color: context.colors.scheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
