// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'package_score.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PackageScore _$PackageScoreFromJson(Map<String, dynamic> json) => PackageScore(
      likeCount: json['likeCount'] as int,
      maxPoints: json['maxPoints'] as int,
      grantedPoints: json['grantedPoints'] as int,
      popularityScore: PackageScore._popularityScoreFromJson(
          json['popularityScore'] as double),
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );

Map<String, dynamic> _$PackageScoreToJson(PackageScore instance) =>
    <String, dynamic>{
      'likeCount': instance.likeCount,
      'maxPoints': instance.maxPoints,
      'grantedPoints': instance.grantedPoints,
      'popularityScore': instance.popularityScore,
      'tags': instance.tags,
      'lastUpdated': instance.lastUpdated.toIso8601String(),
    };
