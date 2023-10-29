// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_packages.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SearchPackage _$SearchPackageFromJson(Map<String, dynamic> json) =>
    SearchPackage(
      package: json['package'] as String,
    );

SearchPackages _$SearchPackagesFromJson(Map<String, dynamic> json) =>
    SearchPackages(
      packages: (json['packages'] as List<dynamic>)
          .map((e) => SearchPackage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
