// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'package.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Package _$PackageFromJson(Map<String, dynamic> json) => Package(
      name: json['name'] as String,
      latest: PackageLatest.fromJson(json['latest'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PackageToJson(Package instance) => <String, dynamic>{
      'name': instance.name,
      'latest': instance.latest,
    };

PackageLatest _$PackageLatestFromJson(Map<String, dynamic> json) =>
    PackageLatest(
      version: json['version'] as String,
      published: DateTime.parse(json['published'] as String),
      pubspec: PackagePubspec.fromJson(json['pubspec'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PackageLatestToJson(PackageLatest instance) =>
    <String, dynamic>{
      'version': instance.version,
      'published': instance.published.toIso8601String(),
      'pubspec': instance.pubspec,
    };

PackagePubspec _$PackagePubspecFromJson(Map<String, dynamic> json) =>
    PackagePubspec(
      name: json['name'] as String,
      description: json['description'] as String,
      version: json['version'] as String,
      repository: json['repository'] as String?,
      documentation: json['documentation'] as String?,
      topics:
          (json['topics'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );

Map<String, dynamic> _$PackagePubspecToJson(PackagePubspec instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'version': instance.version,
      'repository': instance.repository,
      'documentation': instance.documentation,
      'topics': instance.topics,
    };
