import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/pokemon_controller.dart';
import '../../models/data/pokemon.dart';

class ActionsFabsRow extends ConsumerWidget {
  const ActionsFabsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
            heroTag: "buttonCreate",
            child: const Icon(Icons.add),
            onPressed: () =>
                ref.read(pokemonControllerProvider).create(const Pokemon())),
        const SizedBox(width: 16),
        FloatingActionButton(
            heroTag: "buttonDelete",
            child: const Icon(Icons.remove),
            onPressed: () =>
                ref.read(pokemonControllerProvider).delete(const Pokemon().id)),
        const SizedBox(width: 16),
        FloatingActionButton(
            heroTag: "buttonRefresh",
            child: const Icon(Icons.refresh),
            onPressed: () => ref.read(pokemonControllerProvider).refresh()),
      ],
    );
  }
}
