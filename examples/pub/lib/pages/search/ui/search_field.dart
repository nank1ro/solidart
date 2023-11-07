import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:pub/bloc/pub_search/bloc.dart';
import 'package:pub/common/assets.dart';

class SearchField extends StatefulWidget {
  const SearchField({super.key});

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  final controller = TextEditingController();

  // retrieve the search bloc
  late final bloc = context.get<PubSearchBloc>();

  // Whether or not the clear button should be shown
  // Automatically reacts to the searchInput changes
  late final showClearButton =
      Computed(() => bloc.searchInput().search.isNotEmpty);

  @override
  void dispose() {
    controller.dispose();
    showClearButton.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        image: DecorationImage(
          fit: BoxFit.cover,
          image: AssetImage(
            Assets.searchBackground,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        margin: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
        decoration: const BoxDecoration(
          color: Color(0xff35404d),
          borderRadius: BorderRadius.all(Radius.circular(50)),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.grey),
            Expanded(
              child: TextField(
                controller: controller,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: 'Search packages',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: Colors.white),
                onSubmitted: (search) {
                  // update the search input when the user submits the search
                  // and reset the page to the first one
                  bloc.searchInput.updateValue(
                      (value) => value.copyWith(search: search, page: 1));
                },
              ),
            ),
            Show(
              when: showClearButton,
              builder: (context) {
                return IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.clear),
                  color: Colors.white,
                  onPressed: () {
                    // clear the search text
                    controller.clear();

                    // clear the search input when the user presses the clear button
                    bloc.searchInput.updateValue(
                        (value) => value.copyWith(search: '', page: 1));
                  },
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
