import 'package:flutter/material.dart';
import 'package:pub/bloc/pub_search/provider.dart';
import 'package:pub/common/ui/app_bar.dart';
import 'package:pub/pages/search/ui/packages_list.dart';
import 'package:pub/pages/search/ui/search_field.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Provide the PubSearchBloc to descendants
    return const PubSearchBlocProvider(
      child: Scaffold(
        appBar: PubAppBar(
          bottom: SearchField(),
        ),
        body: SearchPackagesList(),
      ),
    );
  }
}
