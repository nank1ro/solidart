import 'package:awesome_flutter_extensions/awesome_flutter_extensions.dart';
import 'package:flutter/material.dart';
import 'package:pub/domain/package_score.dart';

class ScoreView extends StatelessWidget {
  const ScoreView({
    super.key,
    required this.score,
  });

  final PackageScore score;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: _Item(
            value: '${score.likeCount}',
            description: 'LIKES',
          ),
        ),
        _Item(
          value: '${score.grantedPoints}',
          description: 'PUB POINTS',
        ),
        _Item(
          value: '${score.popularityScore}%',
          description: 'POPULARITY',
        ),
      ].separatedBy(const SizedBox(height: 30, child: VerticalDivider())),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.value,
    required this.description,
  });

  final String value;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: context.textStyles.labelLarge.medium.copyWith(
            color: context.colors.primary,
          ),
        ),
        Text(
          description,
          style: context.textStyles.labelSmall.extraLight,
        ),
      ],
    );
  }
}
