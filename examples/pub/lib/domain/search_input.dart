import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
class SearchInput extends Equatable {
  final String search;
  final int page;

  const SearchInput({required this.search, required this.page});

  const SearchInput.empty()
      : search = '',
        page = 1;

  @override
  List<Object> get props => [search, page];

  SearchInput copyWith({
    String? search,
    int? page,
  }) {
    return SearchInput(
      search: search ?? this.search,
      page: page ?? this.page,
    );
  }
}
