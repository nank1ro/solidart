import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:pub/bloc/search.dart';
import 'package:pub/domain/search_packages.dart';

class SearchPackagesList extends StatelessWidget {
  const SearchPackagesList({super.key});

  @override
  Widget build(BuildContext context) {
    // Retrieve the PubSearchBloc from the context
    final bloc = context.get<PubSearchBloc>();
    return RefreshIndicator(
      // refresh the resource when the user pulls down
      onRefresh: () => bloc.searchPackages.refresh(),
      // Using a ResourceBuilder to track each change in the searchPackages resource
      child: ResourceBuilder(
        resource: bloc.searchPackages,
        builder: (context, searchPackagesState) {
          // Handle the different states of the resource
          return searchPackagesState.on(
            ready: (searchPackages) {
              return ListView.separated(
                itemCount: searchPackages.packages.length,
                itemBuilder: (BuildContext context, int index) {
                  return SearchPackageView(
                      searchPackage: searchPackages.packages[index]);
                },
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(child: Text('$error')),
          );
        },
      ),
    );
  }
}

class SearchPackageView extends StatelessWidget {
  const SearchPackageView({
    super.key,
    required this.searchPackage,
  });

  final SearchPackage searchPackage;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(searchPackage.package),
    );
  }
}
