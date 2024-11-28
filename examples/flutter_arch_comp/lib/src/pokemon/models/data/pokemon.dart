import 'package:flutter/widgets.dart';
import 'package:flutter_arch_comp/src/pokemon/models/data/pokemon_api_model.dart';

/// Pokemon represents the data model for a pokemon as it is represented on
/// the UI. This differs from [PokemonApiModel] because lacking 'isDefault'
/// as an example of reduction of model classes
@immutable
class Pokemon {
  const Pokemon({
    this.abilities = const [],
    this.baseExperience = 0,
    this.height = 0,
    this.id = 0,
    this.moves = const [],
    this.name = '',
    this.order = 0,
    this.image = '',
    this.types = const [],
    this.weight = 0,
  });

  final List<AbilityInfo> abilities;
  final int baseExperience;
  final int height;
  final int id;
  final List<MoveInfo> moves;
  final String name;
  final int order;
  final String image;
  final List<TypeInfo> types;
  final int weight;

  factory Pokemon.fromPokemonApiModel(PokemonApiModel model) => Pokemon(
        abilities: model.abilities,
        baseExperience: model.baseExperience,
        height: model.height,
        id: model.id,
        moves: model.moves,
        name: model.name,
        order: model.order,
        image: model.image,
        types: model.types,
        weight: model.weight,
      );

  PokemonApiModel toPokemonApiModel() => PokemonApiModel(
        abilities: abilities,
        baseExperience: baseExperience,
        height: height,
        id: id,
        moves: moves,
        name: name,
        order: order,
        image: image,
        types: types,
        weight: weight,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Pokemon &&
          runtimeType == other.runtimeType &&
          abilities == other.abilities &&
          baseExperience == other.baseExperience &&
          height == other.height &&
          id == other.id &&
          moves == other.moves &&
          name == other.name &&
          order == other.order &&
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
      order.hashCode ^
      image.hashCode ^
      types.hashCode ^
      weight.hashCode;

  get isEmpty => id == 0;
  List<String> get abilitiesList =>
      abilities.map((i) => i.ability.name).toList();
  List<String> get movesList => moves.map((i) => i.move.name).toList();
  List<String> get typesList => types.map((i) => i.type.name).toList();
}
