import 'package:equatable/equatable.dart';
import 'package:github_search/models/search_result_item.dart';
import 'package:json_annotation/json_annotation.dart';

part 'search_result.g.dart';

@JsonSerializable()
class SearchResult extends Equatable {
  const SearchResult({required this.items});

  factory SearchResult.empty() => const SearchResult(items: []);

  factory SearchResult.fromJson(Map<String, dynamic> json) =>
      _$SearchResultFromJson(json);

  Map<String, dynamic> toJson() => _$SearchResultToJson(this);

  final List<SearchResultItem> items;

  @override
  List<Object?> get props => [items];
}
