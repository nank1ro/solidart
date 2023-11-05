import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'package_score.g.dart';

@JsonSerializable()
class PackageScore extends Equatable {
  const PackageScore({
    required this.likeCount,
    required this.maxPoints,
    required this.grantedPoints,
    required this.popularityScore,
    required this.tags,
    required this.lastUpdated,
  });

  factory PackageScore.fromJson(Map<String, dynamic> json) =>
      _$PackageScoreFromJson(json);

  factory PackageScore.mock() {
    return PackageScore(
      likeCount: 20,
      maxPoints: 140,
      grantedPoints: 140,
      popularityScore: 55,
      tags: const [
        "sdk:dart",
        "sdk:flutter",
      ],
      lastUpdated: DateTime.now(),
    );
  }

  final int likeCount;
  final int maxPoints;
  final int grantedPoints;

  @JsonKey(fromJson: _popularityScoreFromJson)
  final int popularityScore;
  final List<String> tags;
  final DateTime lastUpdated;

  static _popularityScoreFromJson(double value) {
    return (value * 100).round();
  }

  List<String> get sdks {
    return tags
        .where((tag) => tag.startsWith('sdk:'))
        .map((tag) => tag.replaceAll('sdk:', ''))
        .toList();
  }

  List<String> get platforms {
    return tags
        .where((tag) => tag.startsWith('platform:'))
        .map((tag) => tag.replaceAll('platform:', ''))
        .toList();
  }

  bool get isNullSafe {
    return tags.contains('is:null-safe');
  }

  bool get isDart3 {
    return tags.contains('is:dart3-compatible');
  }

  String get license {
    final validLicenses = [
      'mit',
      'bsd-3-clause',
      'bsd-2-clause',
      'apache-2.0',
      'gpl-2.0',
      'gpl-3.0',
      'lgpl-2.1',
      'lgpl-3.0',
      'mpl-2.0',
      'unknown',
    ];
    final licenseToName = {
      'mit': 'MIT',
      'bsd-3-clause': 'BSD 3-Clause',
      'bsd-2-clause': 'BSD 2-Clause',
      'apache-2.0': 'Apache 2.0',
      'gpl-2.0': 'GPL 2.0',
      'gpl-3.0': 'GPL 3.0',
      'lgpl-2.1': 'LGPL 2.1',
      'lgpl-3.0': 'LGPL 3.0',
      'mpl-2.0': 'MPL 2.0',
      'unknown': 'Unknown',
    };
    return tags
        .where((element) => element.startsWith('license:'))
        .map((e) => e.replaceFirst('license:', ''))
        .where(validLicenses.contains)
        .map((e) => licenseToName[e])
        .join(', ');
  }

  bool get isFlutterFavorite {
    return tags.contains('is:flutter-favorite');
  }

  @override
  List<Object> get props {
    return [
      likeCount,
      maxPoints,
      grantedPoints,
      popularityScore,
      tags,
      lastUpdated,
    ];
  }
}
