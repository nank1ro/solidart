import 'dart:async';

import 'package:flutter_arch_comp/src/pokemon/models/data/pokemon.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

import '../../core/models/repositories/repository.dart';
import '../views/ui_states/pokemon_details_ui_state.dart';

/// PokemonDetailsController represents the controller of the pokemon
/// details page
class PokemonDetailsController {
  PokemonDetailsController(this.pokemonRepository, this.id) {
    _uploadOnePokemon(id);
  }

  final Repository<Pokemon> pokemonRepository;
  final String id;
  late final _pokemonDetails = Resource<PokemonDetailsItemUiState>(stream: () {
    return pokemonRepository
        .watch(int.parse(id))
        .transform(StreamTransformer.fromHandlers(handleData: (pokemon, sink) {
      sink.add(pokemon == null
          ? const PokemonDetailsItemUiState()
          : PokemonDetailsItemUiState.fromPokemon(pokemon));
    }));
  });

  late final pokemonDetails = _pokemonDetails.toReadSignal();

  void dispose() {
    pokemonRepository.dispose();
  }

  void consumeError() {
    // _state = _state.copy(errorMsg: '');
    // notifyListeners();
  }

  void _uploadOnePokemon(String id) async {
    _onLoading();
    try {
      final pokemon = await pokemonRepository.read(int.parse(id));
      _pokemonDetails.state = ResourceReady(pokemon == null
          ? const PokemonDetailsItemUiState()
          : PokemonDetailsItemUiState.fromPokemon(pokemon));
      _onData(pokemon);
    } on Exception catch (e) {
      _pokemonDetails.state =
          ResourceError('Unable to read pokemon with id $id, $e');
    }
  }

  void _onLoading() {
    // // loading case
    // _state = _state.copy(
    //   pokemon: null,
    //   isFetchingPokemon: true,
    //   errorMsg: '',
    // );
    // notifyListeners();
  }

  void _onData(Pokemon? data) {
    // _state = _state.copy(
    //   pokemon: data == null
    //       ? const PokemonDetailsItemUiState()
    //       : PokemonDetailsItemUiState.fromPokemon(data),
    //   isFetchingPokemon: false,
    //   errorMsg: '',
    // );
    // notifyListeners();
  }

  // void _onError(String msg) {
  //   // unsuccessful case
  //   _state = _state.copy(
  //     pokemon: null,
  //     isFetchingPokemon: false,
  //     errorMsg: msg,
  //   );
  //   notifyListeners();
  // }
}
