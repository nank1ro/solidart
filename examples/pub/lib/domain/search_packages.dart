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
  const SearchPackages({
    required this.packages,
    required this.page,
    this.next,
  });

  factory SearchPackages.fromJson(Map<String, dynamic> json) =>
      _$SearchPackagesFromJson(json);

  final List<SearchPackage> packages;
  final String? next;
  final int page;

  @override
  List<Object?> get props => [packages, page, next];
}
