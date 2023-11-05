import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'package.g.dart';

@JsonSerializable()
class Package extends Equatable {
  const Package({required this.name, required this.latest});

  factory Package.fromJson(Map<String, dynamic> json) =>
      _$PackageFromJson(json);

  final String name;
  final PackageLatest latest;

  @override
  List<Object> get props => [name, latest];
}

@JsonSerializable()
class PackageLatest extends Equatable {
  const PackageLatest({
    required this.version,
    required this.published,
    required this.pubspec,
  });

  factory PackageLatest.fromJson(Map<String, dynamic> json) =>
      _$PackageLatestFromJson(json);

  final String version;
  final DateTime published;
  final PackagePubspec pubspec;

  @override
  List<Object> get props => [version, published, pubspec];
}

@JsonSerializable()
class PackagePubspec extends Equatable {
  const PackagePubspec({
    required this.name,
    required this.description,
    required this.version,
    this.repository,
    this.documentation,
    this.topics,
  });

  factory PackagePubspec.fromJson(Map<String, dynamic> json) =>
      _$PackagePubspecFromJson(json);

  final String name;
  final String description;
  final String version;
  final String? repository;
  final String? documentation;
  final List<String>? topics;

  @override
  List<Object?> get props {
    return [
      name,
      description,
      version,
      repository,
      documentation,
      topics,
    ];
  }
}
