import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:github_search/bloc/github_search_bloc.dart';
import 'package:github_search/models/models.dart';
import 'package:url_launcher/url_launcher_string.dart';

enum Signals {
  isSearchEmpty,
}

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Solid(
      providers: [
        SolidProvider<GithubSearchBloc>(create: () => GithubSearchBloc()),
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
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Solid(
          signals: {
            Signals.isSearchEmpty: () => createSignal<bool>(true),
          },
          child: const Column(
            children: [
              _SearchBar(),
              SizedBox(height: 16),
              Expanded(child: _SearchBody()),
            ],
          ),
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

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  void setIsSearchEmpty(bool isEmpty) {
    context.update(Signals.isSearchEmpty, (_) => isEmpty);
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.get<GithubSearchBloc>();
    return TextField(
      controller: textController,
      decoration: InputDecoration(
        hintText: 'Enter a search term',
        suffixIcon: IconButton(
          onPressed: () {
            textController.clear();
            setIsSearchEmpty(true);
          },
          icon: const Icon(Icons.clear),
        ),
      ),
      onChanged: (search) {
        setIsSearchEmpty(search.isEmpty);
      },
      onSubmitted: (value) {
        bloc.search(value);
      },
    );
  }
}

class _SearchBody extends StatefulWidget {
  // ignore: unused_element
  const _SearchBody({super.key});

  @override
  State<_SearchBody> createState() => __SearchBodyState();
}

class __SearchBodyState extends State<_SearchBody> {
  @override
  Widget build(BuildContext context) {
    final bloc = context.get<GithubSearchBloc>();

    return SignalBuilder(
      signal: context.get<Signal<bool>>(Signals.isSearchEmpty),
      builder: (context, isSearchEmpty, child) {
        if (isSearchEmpty) {
          return const Text('Please enter a term to begin');
        }
        return ResourceBuilder(
          resource: bloc.searchState,
          builder: (context, resourceState) {
            return resourceState.on(
              ready: (value) {
                if (value.items.isEmpty) {
                  return const Text('No results');
                }
                return Stack(
                  children: [
                    ListView.builder(
                      itemCount: value.items.length,
                      itemBuilder: (BuildContext context, int index) {
                        return _SearchResultItem(item: value.items[index]);
                      },
                    ),
                    if (resourceState.isRefreshing)
                      Positioned.fill(
                        child: Container(
                          alignment: Alignment.center,
                          color: Colors.black.withOpacity(0.4),
                          child: const CircularProgressIndicator(),
                        ),
                      ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(child: Text('$error')),
            );
          },
        );
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
