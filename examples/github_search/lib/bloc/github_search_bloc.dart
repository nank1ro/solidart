import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:github_search/models/search_result.dart';
import 'package:github_search/repo/repository.dart';
import 'package:github_search/service/client.dart';
import 'package:github_search/service/in_memory_cache.dart';

import 'package:meta/meta.dart';

@immutable
class GithubSearchBloc {
  GithubSearchBloc({GithubRepository? repository})
      : repository = repository ??
            GithubRepository(
              client: GithubClient(),
              cache: InMemoryCache(const Duration(minutes: 5)),
            );

  final GithubRepository repository;

  final _searchTerm = createSignal('');

  late final searchState = createResource(
    fetcher: () {
      if (_searchTerm().isEmpty) {
        return Future.value(const SearchResult(items: []));
      }
      return repository.search(_searchTerm());
    },
    source: _searchTerm,
  );

  void search(String term) {
    _searchTerm.set(term);
  }

  void dispose() {
    searchState.dispose();
    _searchTerm.dispose();
  }
}
