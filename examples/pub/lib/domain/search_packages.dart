import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'search_packages.g.dart';

@immutable
@JsonSerializable(createToJson: false)
class SearchPackage extends Equatable {
  final String package;

  const SearchPackage({required this.package});

  factory SearchPackage.fromJson(Map<String, dynamic> json) =>
      _$SearchPackageFromJson(json);

  @override
  List<Object> get props => [package];
}

@immutable
@JsonSerializable(createToJson: false)
class SearchPackages extends Equatable {
  const SearchPackages({required this.packages});

  factory SearchPackages.fromJson(Map<String, dynamic> json) =>
      _$SearchPackagesFromJson(json);

  final List<SearchPackage> packages;

  @override
  List<Object> get props => [packages];
}
