import 'package:flutter/cupertino.dart';
import 'package:flutter_arch_comp/src/core/utils/extensions.dart';
import 'package:flutter_arch_comp/src/pokemon/models/data/pokemon.dart';

/// PokemonDetailsUiState represents the UI state for the pokemon details page
@immutable
class PokemonDetailsUiState {
  const PokemonDetailsUiState({
    this.pokemon = const PokemonDetailsItemUiState(),
    this.isFetchingPokemon = false,
    this.errorMsg = '',
  });

  final PokemonDetailsItemUiState pokemon;
  final bool isFetchingPokemon;
  final String errorMsg;

  PokemonDetailsUiState copy({
    PokemonDetailsItemUiState? pokemon,
    bool? isFetchingPokemon,
    String? errorMsg,
  }) {
    return PokemonDetailsUiState(
      pokemon: pokemon ?? this.pokemon,
      isFetchingPokemon: isFetchingPokemon ?? this.isFetchingPokemon,
      errorMsg: errorMsg ?? this.errorMsg,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PokemonDetailsUiState &&
          runtimeType == other.runtimeType &&
          pokemon == other.pokemon &&
          isFetchingPokemon == other.isFetchingPokemon &&
          errorMsg == other.errorMsg;

  @override
  int get hashCode =>
      pokemon.hashCode ^ isFetchingPokemon.hashCode ^ errorMsg.hashCode;
}

/// PokemonDetailsItemUiState represents the UI state for an item of the
/// pokemon details page
@immutable
class PokemonDetailsItemUiState {
  const PokemonDetailsItemUiState({
    this.abilities = '',
    this.baseExperience = '',
    this.height = '',
    this.id = '',
    this.moves = '',
    this.name = '',
    this.image = '',
    this.types = '',
    this.weight = '',
  });

  final String abilities;
  final String baseExperience;
  final String height;
  final String id;
  final String moves;
  final String name;
  final String image;
  final String types;
  final String weight;

  factory PokemonDetailsItemUiState.fromPokemon(Pokemon pokemon) =>
      PokemonDetailsItemUiState(
        abilities: pokemon.abilitiesList.toPlainString(),
        baseExperience: pokemon.baseExperience.toString(),
        height: pokemon.height.toString(),
        id: pokemon.id.toString(),
        moves: pokemon.movesList.toPlainString(),
        name: pokemon.name,
        image: pokemon.image,
        types: pokemon.typesList.toPlainString(),
        weight: pokemon.weight.toString(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PokemonDetailsItemUiState &&
          runtimeType == other.runtimeType &&
          abilities == other.abilities &&
          baseExperience == other.baseExperience &&
          height == other.height &&
          id == other.id &&
          moves == other.moves &&
          name == other.name &&
          image == other.image &&
          types == other.types &&
          weight == other.weight;

  @override
  int get hashCode =>
      abilities.hashCode ^
      baseExperience.hashCode ^
      height.hashCode ^
      id.hashCode ^
      moves.hashCode ^
      name.hashCode ^
      image.hashCode ^
      types.hashCode ^
      weight.hashCode;

  get isEmpty => this == const PokemonDetailsItemUiState();
}
