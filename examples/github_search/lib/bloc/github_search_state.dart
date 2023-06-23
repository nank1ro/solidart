import 'package:equatable/equatable.dart';
import 'package:github_search/models/search_result_item.dart';

sealed class GithubSearchState extends Equatable {
  const GithubSearchState();

  @override
  List<Object> get props => [];
}

final class GithubSearchStateEmpty extends GithubSearchState {}

final class GithubSearchStateLoading extends GithubSearchState {}

final class GithubSearchStateSuccess extends GithubSearchState {
  const GithubSearchStateSuccess(this.items);

  final List<SearchResultItem> items;

  @override
  List<Object> get props => [items];
}

final class GithubSearchStateError extends GithubSearchState {
  const GithubSearchStateError(this.error);

  final String error;

  @override
  List<Object> get props => [error];
}
