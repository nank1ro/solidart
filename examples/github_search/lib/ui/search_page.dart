import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:github_search/bloc/github_search_bloc.dart';
import 'package:github_search/models/models.dart';
import 'package:url_launcher/url_launcher_string.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Solid(
      providers: [
        // Provide the [GithubSearchBloc] to descendants
        Provider<GithubSearchBloc>(
          create: () => GithubSearchBloc(),
          dispose: (bloc) => bloc.dispose(),
        ),
      ],
      child: const SearchPageBody(),
    );
  }
}

class SearchPageBody extends StatelessWidget {
  const SearchPageBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Github Search'),
      ),
      body: const Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: [
            _SearchBar(),
            SizedBox(height: 16),
            Expanded(child: _SearchBody()),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatefulWidget {
  // ignore: unused_element
  const _SearchBar({super.key});

  @override
  State<_SearchBar> createState() => __SearchBarState();
}

class __SearchBarState extends State<_SearchBar> {
  final textController = TextEditingController();
  // retrieve the ancestor [GithubSearchBloc]
  late final bloc = context.get<GithubSearchBloc>();

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  void onClear() {
    textController.clear();
    bloc.search('');
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: textController,
      decoration: InputDecoration(
        hintText: 'Enter a search term',
        suffixIcon: IconButton(
          onPressed: onClear,
          icon: const Icon(Icons.clear),
        ),
      ),
      onSubmitted: (value) {
        // set the current search term
        bloc.search(value);
      },
    );
  }
}

class _SearchBody extends StatelessWidget {
  // ignore: unused_element
  const _SearchBody({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child:
          // Handle the search result state
          SignalBuilder(
        builder: (context, searchResultState) {
          final searchResultState =
              context.get<GithubSearchBloc>().searchResult.state;
          return Stack(
            children: [
              searchResultState.on(
                ready: (searchResult) {
                  if (searchResult.items.isEmpty) {
                    return const Text('No Results');
                  }
                  return _SearchResults(items: searchResult.items);
                },
                error: (error, _) => Text(error.toString()),
                loading: () => const CircularProgressIndicator(),
              ),
              if (searchResultState.isRefreshing)
                Positioned.fill(
                  child: Container(
                    alignment: Alignment.center,
                    color: Colors.black.withOpacity(0.3),
                    child: const CircularProgressIndicator(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({
    // ignore: unused_element
    super.key,
    required this.items,
  });

  final List<SearchResultItem> items;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (BuildContext context, int index) {
        return _SearchResultItem(item: items[index]);
      },
    );
  }
}

class _SearchResultItem extends StatelessWidget {
  const _SearchResultItem({required this.item});

  final SearchResultItem item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Image.network(item.owner.avatarUrl),
      ),
      title: Text(item.fullName),
      onTap: () async {
        if (await canLaunchUrlString(item.htmlUrl)) {
          await launchUrlString(item.htmlUrl);
        }
      },
    );
  }
}
