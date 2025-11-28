import 'dart:convert';

import 'package:disco/disco.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:http/http.dart' as http;
import 'package:infinite_scroll/domain/post.dart';

@immutable
class PostController {
  static const _postLimit = 20;
  static const _throttleDuration = Duration(milliseconds: 300);

  // Provider
  static final provider = Provider.withArgument(
    (_, http.Client client) => PostController(httpClient: client),
  );

  PostController({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  final posts = ListSignal<Post>([]);
  final hasReachedMax = Signal(false);

  final _startIndex = Signal<int>(0);
  late final postsResource = Resource(
    _getPosts,
    autoDispose: false,
    debounceDelay: _throttleDuration,
    source: _startIndex,
  );

  Future<void> _getPosts() async {
    final index = _startIndex.value;
    final response = await _fetchPosts(startIndex: index);
    if (response.isEmpty) {
      hasReachedMax.value = true;
      return;
    }

    // update state
    posts.updateValue((curr) => [...curr, ...response]);
  }

  void loadMore() {
    if (!hasReachedMax.value && !postsResource.state.isLoading) {
      _startIndex.value = posts.length;
    }
  }

  /// https://jsonplaceholder.typicode.com/posts?_start=0&_limit=20
  Future<List<Post>> _fetchPosts({required int startIndex}) async {
    final response = await _httpClient.get(
      Uri.https('jsonplaceholder.typicode.com', '/posts', <String, String>{
        '_start': '$startIndex',
        '_limit': '$_postLimit',
      }),
    );

    if (response.statusCode == 200) {
      final body = json.decode(response.body) as List;
      return List<Post>.from(body.map((x) => Post.fromJson(x)));
    }

    throw Exception('error fetching posts');
  }
}
