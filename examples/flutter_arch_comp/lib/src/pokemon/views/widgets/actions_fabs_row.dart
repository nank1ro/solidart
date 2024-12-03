import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

import '../../controllers/pokemon_controller.dart';
import '../../models/data/pokemon.dart';

class ActionsFabsRow extends StatelessWidget {
  const ActionsFabsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final pokemonController = context.get<PokemonController>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          heroTag: "buttonCreate",
          child: const Icon(Icons.add),
          onPressed: () => pokemonController.create(const Pokemon()),
        ),
        const SizedBox(width: 16),
        FloatingActionButton(
          heroTag: "buttonDelete",
          child: const Icon(Icons.remove),
          onPressed: () => pokemonController.delete(const Pokemon().id),
        ),
        const SizedBox(width: 16),
        FloatingActionButton(
          heroTag: "buttonRefresh",
          child: const Icon(Icons.refresh),
          onPressed: () => pokemonController.refresh(),
        ),
      ],
    );
  }
}
