import 'dart:convert';

import 'package:flutter_arch_comp/src/core/utils/demo_hacks_helper.dart';
import 'package:http/http.dart' as http;

import '../../../core/models/data_sources/data_source.dart';
import '../data/pokemon_api_model.dart';

PokemonApiModel parsePokemon(String responseBody) {
  final parsed = json.decode(responseBody) as Map<String, dynamic>;
  return PokemonApiModel.fromJson(parsed);
}

/// PokemonRemoteDataSource represents a remote [DataSource] for
/// [PokemonApiModel]. Remote data sources are backed up by the server
class PokemonRemoteDataSource implements DataSource<PokemonApiModel> {
  @override
  Future<void> create(PokemonApiModel pokemon) async {
    try {
      // mocks the pokemon as created if I can poke the server
      await http
          .get(Uri.parse('https://pokeapi.co/api/v2/pokemon/1/'))
          .timeout(const Duration(seconds: 4));
    } on Exception catch (e) {
      throw Exception(
          'Unable to create pokemon with id ${pokemon.id} from API, ${e.toString()}');
    }
  }

  @override
  Future<void> createAll(List<PokemonApiModel> data) async {
    try {
      // mocks the pokemon as created if I can poke the server
      await http
          .get(Uri.parse('https://pokeapi.co/api/v2/pokemon/1/'))
          .timeout(const Duration(seconds: 4));
    } on Exception catch (e) {
      throw Exception('Unable to create all pokemon from API, ${e.toString()}');
    }
  }

  @override
  Future<void> delete(int id) async {
    try {
      // mocks the pokemon as deleted if I can poke the server
      await http
          .get(Uri.parse('https://pokeapi.co/api/v2/pokemon/1/'))
          .timeout(const Duration(seconds: 4));
    } on Exception catch (e) {
      throw Exception(
          'Unable to delete pokemon with id $id from API, ${e.toString()}');
    }
  }

  @override
  Future<PokemonApiModel?> read(int id) async {
    try {
      final res = await http
          .get(Uri.parse('https://pokeapi.co/api/v2/pokemon/$id/'))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        return parsePokemon(res.body);
      } else {
        throw Exception();
      }
    } on Exception catch (e) {
      throw Exception(
          'Unable to read pokemon with id $id from API, ${e.toString()}');
    }
  }

  @override
  Future<List<PokemonApiModel>> readAll() async {
    /// create pokemon urls
    final urls = <String>[];
    for (int i = DemoHacksHelper.instance.lowestId;
        i <= DemoHacksHelper.instance.highestId + 1;
        i++) {
      urls.add('https://pokeapi.co/api/v2/pokemon/$i/');
    }

    try {
      final pokemon = await Future.wait<PokemonApiModel>(urls.map((url) async {
        final res = await http.get(Uri.parse(url));
        if (res.statusCode == 200) {
          return parsePokemon(res.body);
        } else {
          throw Exception();
        }
      }));

      return pokemon;
    } on Exception catch (e) {
      throw Exception('Unable to read all pokemon from API, ${e.toString()}');
    }
  }

  @override
  Future<void> update(PokemonApiModel pokemon) async {
    try {
      // mocks the pokemon as updated if I can poke the server
      await http
          .get(Uri.parse('https://pokeapi.co/api/v2/pokemon/1/'))
          .timeout(const Duration(seconds: 4));
    } on Exception catch (e) {
      throw Exception(
          'Unable to update pokemon with id ${pokemon.id} from API, ${e.toString()}');
    }
  }
}
