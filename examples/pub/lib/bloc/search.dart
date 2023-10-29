import 'package:pub/domain/search_input.dart';
import 'package:pub/repository.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

class PubSearchBloc {
  PubSearchBloc({PubRepository? repository})
      : _repository = repository ?? PubRepository();

  final PubRepository _repository;

  /// The search input entered by the user
  final searchInput = Signal(const SearchInput.empty());

  /// Handles the fetching of current search results
  late final searchPackages = Resource(
    fetcher: () => _repository.searchPackages(
      page: searchInput().page,
      search: searchInput().search,
    ),
    // React to changes in the search input
    source: searchInput,
  );

  void dispose() {
    searchInput.dispose();
    searchPackages.dispose();
  }
}
