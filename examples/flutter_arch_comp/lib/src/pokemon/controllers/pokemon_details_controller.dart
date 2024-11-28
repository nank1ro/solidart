import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_arch_comp/src/pokemon/models/data/pokemon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/repositories/repository.dart';
import '../models/repositories/pokemon_repository.dart';
import '../views/ui_states/pokemon_details_ui_state.dart';

/// PokemonDetailsController represents the controller of the pokemon
/// details page
class PokemonDetailsController extends ChangeNotifier {
  PokemonDetailsController(this.pokemonRepository, this.id) {
    _pokemonSubscription =
        pokemonRepository.watch(int.parse(id)).listen((pokemon) async {
      final changed = pokemon == null
          ? const PokemonDetailsItemUiState()
          : PokemonDetailsItemUiState.fromPokemon(pokemon);
      if (state.pokemon != changed) {
        _onLoading();
        // artificial delay
        await Future.delayed(const Duration(milliseconds: 500));
        _onData(pokemon);
      }
    });
    _uploadOnePokemon(id);
  }

  final Repository<Pokemon> pokemonRepository;
  final String id;
  late final StreamSubscription _pokemonSubscription;
  // initial state is loading
  PokemonDetailsUiState _state =
      const PokemonDetailsUiState(isFetchingPokemon: true);
  PokemonDetailsUiState get state => _state;

  @override
  void dispose() {
    _pokemonSubscription.cancel();
    pokemonRepository.dispose();
    super.dispose();
  }

  void consumeError() {
    _state = _state.copy(errorMsg: '');
    notifyListeners();
  }

  void _uploadOnePokemon(String id) async {
    _onLoading();
    try {
      final pokemon = await pokemonRepository.read(int.parse(id));
      _onData(pokemon);
    } on Exception catch (e) {
      _onError('Unable to read pokemon with id $id, $e');
    }
  }

  void _onLoading() {
    // loading case
    _state = _state.copy(
      pokemon: null,
      isFetchingPokemon: true,
      errorMsg: '',
    );
    notifyListeners();
  }

  void _onData(Pokemon? data) {
    _state = _state.copy(
      pokemon: data == null
          ? const PokemonDetailsItemUiState()
          : PokemonDetailsItemUiState.fromPokemon(data),
      isFetchingPokemon: false,
      errorMsg: '',
    );
    notifyListeners();
  }

  void _onError(String msg) {
    // unsuccessful case
    _state = _state.copy(
      pokemon: null,
      isFetchingPokemon: false,
      errorMsg: msg,
    );
    notifyListeners();
  }
}

/// pokemonControllerProvider provides the pokemon controller
final pokemonDetailsControllerProvider =
    ChangeNotifierProvider.family<PokemonDetailsController, String>((ref, id) {
  final pokemonRepository = ref.read(pokemonRepositoryProvider);
  return PokemonDetailsController(pokemonRepository, id);
});
