import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'search_result_error.g.dart';

@JsonSerializable()
class SearchResultError extends Equatable implements Exception {
  const SearchResultError({required this.message});

  factory SearchResultError.fromJson(Map<String, dynamic> json) =>
      _$SearchResultErrorFromJson(json);

  Map<String, dynamic> toJson() => _$SearchResultErrorToJson(this);

  final String message;

  @override
  List<Object?> get props => [message];
}
