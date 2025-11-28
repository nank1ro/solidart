import 'package:disco/disco.dart';
import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:http/http.dart' as http;
import 'package:infinite_scroll/controllers/post_controller.dart';
import 'package:infinite_scroll/domain/post.dart';

class PostsPage extends StatelessWidget {
  const PostsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      providers: [PostController.provider(http.Client())],
      child: Scaffold(
        appBar: AppBar(title: const Text('Posts')),
        body: const PostsList(),
      ),
    );
  }
}

class PostsList extends StatefulWidget {
  const PostsList({super.key});

  @override
  State<PostsList> createState() => _PostsListState();
}

class _PostsListState extends State<PostsList> {
  final _scrollController = ScrollController();
  late final _postController = PostController.provider.of(context);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (_, _) {
        final postsState = _postController.postsResource.state;
        final hasReachedMax = _postController.hasReachedMax.value;
        final posts = _postController.posts;

        return postsState.when(
          ready: (_) {
            if (posts.isEmpty) {
              return const Center(child: Text('no posts'));
            }

            return ListView.builder(
              itemBuilder: (BuildContext context, int index) {
                return index >= posts.length
                    ? const BottomLoader()
                    : PostListItem(post: posts[index]);
              },
              itemCount: hasReachedMax ? posts.length : posts.length + 1,
              controller: _scrollController,
            );
          },
          error: (e, st) => Text('Error : $e'),
          loading: () => const Center(child: CircularProgressIndicator.adaptive()),
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();

    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) _postController.loadMore();
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }
}

class BottomLoader extends StatelessWidget {
  const BottomLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator.adaptive(strokeWidth: 1.5),
      ),
    );
  }
}

class PostListItem extends StatelessWidget {
  const PostListItem({required this.post, super.key});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListTile(
      leading: Text('${post.id}', style: textTheme.bodySmall),
      title: Text(post.title),
      isThreeLine: true,
      subtitle: Text(post.body),
      dense: true,
    );
  }
}
