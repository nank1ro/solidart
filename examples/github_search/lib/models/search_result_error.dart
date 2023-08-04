import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'search_result_error.g.dart';

@JsonSerializable(createToJson: false)
class SearchResultError extends Equatable implements Exception {
  const SearchResultError({required this.message});

  factory SearchResultError.fromJson(Map<String, dynamic> json) =>
      _$SearchResultErrorFromJson(json);

  final String message;

  @override
  List<Object?> get props => [message];
}
