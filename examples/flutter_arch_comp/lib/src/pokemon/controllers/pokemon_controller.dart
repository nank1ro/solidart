import 'dart:async';
import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:flutter_arch_comp/src/pokemon/models/data/pokemon.dart';
import 'package:flutter_arch_comp/src/pokemon/views/ui_states/pokemon_ui_state.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

import '../../core/models/repositories/repository.dart';
import '../../core/utils/demo_hacks_helper.dart';

/// PokemonController represents the controller of the pokemon page
class PokemonController extends ChangeNotifier {
  PokemonController(this.pokemonRepository);
  final Repository<Pokemon> pokemonRepository;

  late final _pokemons = Resource<List<PokemonItemUiState>>(stream: () {
    return pokemonRepository
        .watchAll()
        .transform(StreamTransformer.fromHandlers(handleData: (pokemons, sink) {
      sink.add(UnmodifiableListView(
          pokemons.map((p) => PokemonItemUiState.fromPokemon(p)).toList()));
    }));
  });

  late final pokemons = _pokemons.toReadSignal();

  Future<void> create(Pokemon pokemon) async {
    /// demo only, the param 'pokemon' passed to create() is not really used;
    /// usually it would come from the user adding a new entry on UI, or from
    /// a push notification or firebase, but in this demo we use always the
    /// first next from remote
    final next = await DemoHacksHelper.instance.nextPokemonFromRemote();
    if (next != null) {
      _onLoading();
      try {
        await pokemonRepository.create(next);
        // _onData is handled through watchPokemon
      } on Exception catch (e) {
        _onError('Unable to create pokemon with id ${next.id}, $e');
      }
    }
  }

  void update(Pokemon pokemon) {}

  void delete(int id) async {
    /// demo only, the param 'id' passed to delete() is not really used;
    /// usually it would come from the user swiping a given pokemon away from
    /// the list on UI, but in this demo we use always the first pokemon from
    /// local
    final first = await DemoHacksHelper.instance.firstPokemonFromLocal();
    if (first != null) {
      _onLoading();
      try {
        await pokemonRepository.delete(first.id);
        // _onData is handled through watchPokemon
      } on Exception catch (e) {
        _onError('Unable to delete pokemon with id ${first.id}, $e');
      }
    }
  }

  void refresh() async {
    _onLoading();
    try {
      await pokemonRepository.refresh();
    } on Exception catch (e) {
      _onError('Unable to refresh pokemon, $e');
    }
  }

  void uploadPokemon() async {
    _onLoading();
    try {
      final pokemon = await pokemonRepository.readAll();
      _onData(pokemon);
    } on Exception catch (e) {
      _onError('Unable to upload pokemon, $e');
    } finally {
      // async call
      refresh();
    }
  }

  @override
  void dispose() {
    pokemonRepository.dispose();
    super.dispose();
  }

  /// demo only
  void resetLocal() {
    DemoHacksHelper.instance.resetLocal();
    _pokemons.state = ResourceReady([]);
    notifyListeners();
  }

  void _onLoading() {
    _pokemons.update(
      (state) => state.map(
        ready: (ready) {
          return ready.copyWith(isRefreshing: true);
        },
        error: (error) {
          return error.copyWith(isRefreshing: true);
        },
        loading: (_) {
          return ResourceState.loading();
        },
      ),
    );
  }
}
