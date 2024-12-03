import 'package:flutter/material.dart';
import 'package:flutter_arch_comp/src/pokemon/models/data_sources/pokemon_local_data_source.dart';
import 'package:flutter_arch_comp/src/pokemon/models/data_sources/pokemon_remote_data_source.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

import 'src/core/app.dart';
import 'src/network/utils/connectivity.dart';
import 'src/pokemon/controllers/pokemon_controller.dart';
import 'src/pokemon/models/repositories/pokemon_repository.dart';
import 'src/settings/controllers/settings_controller.dart';
import 'src/settings/services/settings_service.dart';

void main() async {
  runApp(
    Solid(
      providers: [
        Provider<PokemonRepository>(
          create: () => PokemonRepository(PokemonLocalDataSource(),
              PokemonRemoteDataSource(), Connectivity.instance),
        ),
      ],
      builder: (context) {
        return Solid(
          providers: [
            Provider<SettingsController>(
              create: () => SettingsController(SettingsService()),
            ),
            Provider<PokemonController>(
              create: () => PokemonController(context.get<PokemonRepository>()),
            )
          ],
          child: MyApp(),
        );
      },
    ),
  );
}
