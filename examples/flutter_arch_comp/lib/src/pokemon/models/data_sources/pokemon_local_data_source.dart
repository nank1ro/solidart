import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_arch_comp/src/core/models/data_sources/data_source.dart';
import 'package:flutter_arch_comp/src/pokemon/models/data/pokemon_api_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/demo_hacks_helper.dart';

/// PokemonLocalDataSource represents a local [DataSource] for
/// [PokemonApiModel]. Local data sources are backed up by the database, but
/// in this case I use shared prefs to keep it simple
class PokemonLocalDataSource implements DataSource<PokemonApiModel> {
  static const _pokemonKey = '_pokemonKey';

  @override
  Future<void> create(PokemonApiModel pokemon) async {
    final all = await readAll();
    final first = all.firstWhere((p) => p.id == pokemon.id,
        orElse: () => const PokemonApiModel());
    if (first.isEmpty) {
      all.add(pokemon);
      await createAll(all);
    } else {
      update(pokemon);
    }
  }

  @override
  Future<void> createAll(List<PokemonApiModel> pokemon) async {
    // TODO(alesalv): introduce failures
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonObj = pokemon.map((p) => p.toJson()).toList();
      final jsonStr = json.encode(jsonObj);
      prefs.setString(_pokemonKey, jsonStr);
      // this is a demo hack
      DemoHacksHelper.instance.updateIds(pokemon);
    } on Exception catch (e) {
      debugPrint('Failed to encode json, ${e.toString()}');
      throw Exception('Failed to encode json, ${e.toString()}');
    }
  }

  @override
  Future<PokemonApiModel?> read(int id) async {
    final pokemonList = await readAll();
    final pokemon = pokemonList.firstWhere((p) => p.id == id,
        orElse: () => const PokemonApiModel());
    return pokemon.isEmpty ? null : pokemon;
  }

  @override
  Future<List<PokemonApiModel>> readAll() async {
    // TODO(alesalv): introduce failures
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_pokemonKey) ?? '[]';
    try {
      final jsonObj = json.decode(jsonStr) as List<dynamic>;
      final decoded = jsonObj.map((j) => PokemonApiModel.fromJson(j)).toList();
      // this is a demo hack
      DemoHacksHelper.instance.updateIds(decoded);
      return decoded;
    } on Exception catch (e) {
      debugPrint('Failed to decode json, ${e.toString()}');
      throw Exception('Failed to decode json, ${e.toString()}');
    }
  }

  @override
  Future<void> update(PokemonApiModel pokemon) async {
    final all = await readAll();
    final index = all.indexWhere((p) => p.id == pokemon.id);
    if (index != -1) {
      all[index] = pokemon;
      await createAll(all);
    }
  }

  @override
  Future<void> delete(int id) async {
    final all = await readAll();
    final index = all.indexWhere((p) => p.id == id);
    if (index != -1) {
      all.removeAt(index);
      await createAll(all);
    }
  }

  // demo only
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pokemonKey, '[]');
    // this is a demo hack
    DemoHacksHelper.instance.updateIds([]);
  }
}
