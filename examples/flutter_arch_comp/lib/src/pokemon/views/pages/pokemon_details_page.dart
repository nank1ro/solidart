import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/views/widgets/circular_image.dart';
import '../../controllers/pokemon_details_controller.dart';
import '../widgets/loading_indicator.dart';

/// Displays detailed information about a pokemon
class PokemonDetailsPage extends StatelessWidget {
  const PokemonDetailsPage({super.key});

  static const routeName = 'pokemon_details';

  @override
  Widget build(BuildContext context) {
    final pokemonId =
        (ModalRoute.of(context)!.settings.arguments as PokemonDetailsViewArgs)
            .id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokemon Details'),
      ),
      body: Stack(children: [
        _PokemonDetailsPanel(pokemonId),
        _LoadingIndicator(pokemonId),
        _ErrorIndicator(pokemonId),
      ]),
    );
  }
}

class PokemonDetailsViewArgs {
  final String id;
  const PokemonDetailsViewArgs(this.id);
}

class _LoadingIndicator extends ConsumerWidget {
  const _LoadingIndicator(this.id);
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFetchingPokemon = ref.watch(pokemonDetailsControllerProvider(id)
        .select((c) => c.state.isFetchingPokemon));
    return isFetchingPokemon
        ? const LoadingIndicator()
        : const SizedBox.shrink();
  }
}

class _PokemonDetailsPanel extends ConsumerWidget {
  const _PokemonDetailsPanel(this.id);
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pokemon = ref.watch(
        pokemonDetailsControllerProvider(id).select((c) => c.state.pokemon));
    return pokemon.isEmpty
        ? Center(
            child: Text(
              'No information for pokemon with id $id',
              style: const TextStyle(fontSize: 20),
            ),
          )
        : SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: CircularImage(imageUrl: pokemon.image, size: 200),
                ),
                _Tile(title: 'Name', content: pokemon.name),
                _Tile(title: 'Experience', content: pokemon.baseExperience),
                _Tile(title: 'Height (dm)', content: pokemon.height),
                _Tile(title: 'Weight (hg)', content: pokemon.weight),
                _Tile(title: 'Types', content: pokemon.types.toString()),
                _Tile(title: 'Abilities', content: pokemon.abilities),
                _Tile(title: 'Moves', content: pokemon.moves.toString()),
              ],
            ),
          );
  }
}

class _ErrorIndicator extends ConsumerWidget {
  const _ErrorIndicator(this.id);
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final msg = ref.watch(
        pokemonDetailsControllerProvider(id).select((c) => c.state.errorMsg));

    if (msg.isNotEmpty) {
      WidgetsBinding.instance
          .addPostFrameCallback((final _) => _showSnackbar(context, ref, msg));
    }
    return const SizedBox.shrink();
  }

  void _showSnackbar(BuildContext context, WidgetRef ref, String msg) {
    final snackBar = SnackBar(content: Text('Oops something went wrong: $msg'));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    ref.read(pokemonDetailsControllerProvider(id)).consumeError();
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.title, required this.content});
  final String title;
  final String content;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text('${title.toUpperCase()}: $content'),
    );
  }
}
