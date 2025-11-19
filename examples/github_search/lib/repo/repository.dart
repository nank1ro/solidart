import 'package:github_search/models/models.dart';
import 'package:github_search/service/client.dart';
import 'package:github_search/service/in_memory_cache.dart';

class GithubRepository {
  GithubRepository({required this.client, required this.cache});

  final InMemoryCache cache;
  final GithubClient client;

  Future<SearchResult> search(String term) async {
    return await cache.fetch(() => client.search(term));
  }
}
