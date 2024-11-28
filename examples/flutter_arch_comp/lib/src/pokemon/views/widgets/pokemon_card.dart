import 'package:flutter/material.dart';

import '../../../core/views/widgets/circular_image.dart';
import '../pages/pokemon_details_page.dart';
import '../ui_states/pokemon_ui_state.dart';

/// PokemonCard represents a card to show some pokemon information, like an
/// icon, the name, its weight and height
class PokemonCard extends StatelessWidget {
  const PokemonCard(this.pokemon, {super.key});

  final PokemonItemUiState pokemon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: ListTile(
            leading: CircularImage(imageUrl: pokemon.image, size: 55),
            title: Text(
              pokemon.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Text('ID: ${pokemon.id}'),
                  const SizedBox(
                    width: 16,
                  ),
                  Text('Order: ${pokemon.order}'),
                ],
              ),
            ),
            onTap: () {
              // Navigate to the details page. If the user leaves and returns to
              // the app after it has been killed while running in the
              // background, the navigation stack is restored.
              Navigator.pushNamed(
                context,
                PokemonDetailsPage.routeName,
                arguments: PokemonDetailsViewArgs(pokemon.id),
              );
            }),
      ),
    );
  }
}
