import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:github_search/bloc/github_search_state.dart';
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

  final searchState = createSignal<GithubSearchState>(GithubSearchStateEmpty());

  Future<void> search(
    String term,
  ) async {
    if (term.isEmpty) {
      return searchState.set(GithubSearchStateEmpty());
    }

    searchState.set(GithubSearchStateLoading());

    try {
      final results = await _repository.search(term);
      searchState.value = GithubSearchStateSuccess(results.items);
    } catch (error) {
      searchState.value = error is SearchResultError
          ? GithubSearchStateError(error.message)
          : const GithubSearchStateError('something went wrong');
    }
  }

  void dispose() {
    searchState.dispose();
  }
}
