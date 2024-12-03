import 'package:flutter/material.dart';
import 'package:flutter_arch_comp/src/core/utils/extensions.dart';
import 'package:flutter_arch_comp/src/pokemon/models/repositories/pokemon_repository.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

import '../../../core/views/widgets/circular_image.dart';
import '../../controllers/pokemon_details_controller.dart';
import '../widgets/loading_indicator.dart';

/// Displays detailed information about a pokemon
class PokemonDetailsPage extends StatefulWidget {
  const PokemonDetailsPage({super.key, required this.pokemonId});

  static const routeName = 'pokemon_details';
  final String pokemonId;

  @override
  State<PokemonDetailsPage> createState() => _PokemonDetailsPageState();
}

class _PokemonDetailsPageState extends State<PokemonDetailsPage> {
  @override
  Widget build(BuildContext context) {
    return Solid(
      providers: [
        Provider<PokemonDetailsController>(
            create: () => PokemonDetailsController(
                context.get<PokemonRepository>(), widget.pokemonId))
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pokemon Details'),
        ),
        body: _PokemonDetailsPanel(widget.pokemonId),
      ),
    );
  }
}

class PokemonDetailsViewArgs {
  final String id;
  const PokemonDetailsViewArgs(this.id);
}

class _PokemonDetailsPanel extends StatefulWidget {
  const _PokemonDetailsPanel(this.id);
  final String id;

  @override
  State<_PokemonDetailsPanel> createState() => _PokemonDetailsPanelState();
}

class _PokemonDetailsPanelState extends State<_PokemonDetailsPanel> {
  late final controller = context.get<PokemonDetailsController>();

  @override
  void initState() {
    super.initState();
    controller.pokemonDetails.observe((previous, current) {
      if (current.hasError) {
        context.showErrorSnackbar(current.error.toString());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context, child) {
        return controller.pokemonDetails().on(
              ready: (pokemon) {
                return pokemon.isEmpty
                    ? Center(
                        child: Text(
                          'No information for pokemon with id ${widget.id}',
                          style: const TextStyle(fontSize: 20),
                        ),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: CircularImage(
                                  imageUrl: pokemon.image, size: 200),
                            ),
                            _Tile(title: 'Name', content: pokemon.name),
                            _Tile(
                                title: 'Experience',
                                content: pokemon.baseExperience),
                            _Tile(
                                title: 'Height (dm)', content: pokemon.height),
                            _Tile(
                                title: 'Weight (hg)', content: pokemon.weight),
                            _Tile(
                                title: 'Types',
                                content: pokemon.types.toString()),
                            _Tile(
                                title: 'Abilities', content: pokemon.abilities),
                            _Tile(
                                title: 'Moves',
                                content: pokemon.moves.toString()),
                          ],
                        ),
                      );
              },
              loading: () => LoadingIndicator(),
              error: (error, stackTrace) => Text('Error: $error'),
            );
      },
    );
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
