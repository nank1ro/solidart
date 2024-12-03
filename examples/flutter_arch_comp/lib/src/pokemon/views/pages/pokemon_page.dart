import 'package:flutter/material.dart';
import 'package:flutter_arch_comp/src/core/utils/extensions.dart';
import 'package:flutter_arch_comp/src/pokemon/controllers/pokemon_controller.dart';
import 'package:flutter_arch_comp/src/pokemon/views/widgets/actions_fabs_row.dart';
import 'package:flutter_arch_comp/src/pokemon/views/widgets/actions_menu_button.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:flutter_svg/svg.dart';

import '../widgets/loading_indicator.dart';
import '../widgets/pokemon_card.dart';

/// PokemonPage represents a page to displays a list of pokemon, showing a
/// loading indicator for fetching operations and an error indicator for errors
class PokemonPage extends StatefulWidget {
  const PokemonPage({super.key});

  static const routeName = 'pokemon_page';

  @override
  State<PokemonPage> createState() => _PokemonPageState();
}

class _PokemonPageState extends State<PokemonPage> {
  late final controller = context.get<PokemonController>();

  @override
  void initState() {
    super.initState();
    // Start with a list of pokemons
    controller.uploadPokemon();

    // React to the error
    controller.pokemons.observe((previous, current) {
      if (current.hasError) {
        context.showErrorSnackbar(current.error.toString());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokemon'),
        actions: const <Widget>[ActionsMenuButton()],
      ),
      body: _PokemonList(),
      floatingActionButton: const ActionsFabsRow(),
    );
  }
}

class _PokemonList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = context.get<PokemonController>();

    return SignalBuilder(
      builder: (context, child) {
        final pokemonsState = controller.pokemons();
        return Stack(
          children: [
            pokemonsState.on(
              ready: (items) {
                if (items.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 200),
                    child: Center(
                      child: Column(
                        children: [
                          SvgPicture.asset(
                            'assets/images/void.svg',
                            width: 150,
                            height: 150, //asset location
                          ),
                          const SizedBox(
                            height: 24,
                          ),
                          const Text(
                            'No pokemon yet',
                            style: TextStyle(fontSize: 20),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  // Providing a restorationId allows the ListView to restore the
                  // scroll position when a user leaves and returns to the app after it
                  // has been killed while running in the background.
                  restorationId: 'pokemonListView',
                  itemCount: items.length,
                  itemBuilder: (BuildContext context, int index) {
                    return PokemonCard(items[index]);
                  },
                );
              },
              loading: () => const LoadingIndicator(),
              error: (error, stackTrace) => Text('Error: $error'),
            ),
            // If the resource is refreshing its state, show a loading indicator while showing the old state.
            if (pokemonsState.isRefreshing) LoadingIndicator(),
          ],
        );
      },
    );
  }
}
