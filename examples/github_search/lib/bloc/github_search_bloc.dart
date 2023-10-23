import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:github_search/models/models.dart';
import 'package:github_search/repo/repository.dart';
import 'package:github_search/service/client.dart';
import 'package:github_search/service/in_memory_cache.dart';

import 'package:meta/meta.dart';

@immutable
class GithubSearchBloc {
  GithubSearchBloc({GithubRepository? repository})
      : _repository = repository ??
            GithubRepository(
              client: GithubClient(),
              cache: InMemoryCache(const Duration(minutes: 5)),
            );

  final GithubRepository _repository;

  // Keeps track of the current search term
  final _searchTerm = Signal('');

  /// Handles the fetching of current search results
  late final searchResult = Resource(
    fetcher: _search,
    source: _searchTerm,
  );

  // Sets the current search term
  void search(String term) => _searchTerm.set(term);

  // Fetches the current search term
  //
  // If the term is empty, returns an empty [SearchResult]
  Future<SearchResult> _search() async {
    if (_searchTerm().isEmpty) return SearchResult.empty();
    return _repository.search(_searchTerm());
  }

  void dispose() {
    _searchTerm.dispose();
    searchResult.dispose();
  }
}
