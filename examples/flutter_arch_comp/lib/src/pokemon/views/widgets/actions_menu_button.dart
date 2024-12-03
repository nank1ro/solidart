import 'package:flutter/material.dart';
import 'package:flutter_arch_comp/src/core/utils/demo_hacks_helper.dart';
import 'package:flutter_arch_comp/src/pokemon/models/repositories/pokemon_repository.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

class ActionsMenuButton extends StatelessWidget {
  const ActionsMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final pokemonRepository = context.get<PokemonRepository>();
    return PopupMenuButton<_MenuActions>(
        onSelected: (_MenuActions item) async {
          // this mocks an event which could happen via firebase, or from
          // a background process, or even from another UI, so the
          // refresh call is made directly via the repository and not via
          // the controller
          switch (item) {
            case _MenuActions.create:
              final next =
                  await DemoHacksHelper.instance.nextPokemonFromRemote();
              if (next != null) {
                pokemonRepository.create(next);
              }
              break;
            case _MenuActions.delete:
              final first =
                  await DemoHacksHelper.instance.firstPokemonFromLocal();
              if (first != null) {
                pokemonRepository.delete(first.id);
              }
              break;
            case _MenuActions.refresh:
              pokemonRepository.refresh();
              break;
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<_MenuActions>>[
              const PopupMenuItem<_MenuActions>(
                value: _MenuActions.create,
                child: Text('Create'),
              ),
              const PopupMenuItem<_MenuActions>(
                value: _MenuActions.delete,
                child: Text('Delete'),
              ),
              const PopupMenuItem<_MenuActions>(
                value: _MenuActions.refresh,
                child: Text('Refresh'),
              ),
            ]);
  }
}

enum _MenuActions { create, delete, refresh }
