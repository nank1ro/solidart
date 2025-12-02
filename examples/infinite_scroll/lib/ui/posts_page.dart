import 'package:disco/disco.dart';
import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:infinite_scroll/notifiers/posts_notifier.dart';
import 'package:infinite_scroll/domain/post.dart';

class PostsPage extends StatelessWidget {
  const PostsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      providers: [PostsNotifier.provider],
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
  final scrollController = ScrollController();
  late final postsNotifier = PostsNotifier.provider.of(context);
  bool hasTriggeredLoadMore = false; // prevent multiple load more calls

  @override
  void initState() {
    super.initState();
    scrollController.addListener(onScroll);
  }

  @override
  void dispose() {
    scrollController.removeListener(onScroll);
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (_, _) {
        final hasReachedMax = postsNotifier.hasReachedMax.value;
        return postsNotifier.posts.state.when(
          ready: (posts) {
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
              controller: scrollController,
            );
          },
          error: (e, st) => Text('Error : $e'),
          loading: () =>
              const Center(child: CircularProgressIndicator.adaptive()),
        );
      },
    );
  }

  void onScroll() {
    if (isBottom && !hasTriggeredLoadMore) {
      hasTriggeredLoadMore = true;
      postsNotifier.loadMore();
    }

    if (!isBottom) {
      hasTriggeredLoadMore = false;
    }
  }

  bool get isBottom {
    if (!scrollController.hasClients) return false;
    final maxScroll = scrollController.position.maxScrollExtent;
    final currentScroll = scrollController.offset;
    return currentScroll >= (maxScroll * 0.95);
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
