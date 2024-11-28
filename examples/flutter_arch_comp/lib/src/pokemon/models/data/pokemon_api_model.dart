import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pokemon_api_model.g.dart';

String _extractImage(Object input) {
  if (input is Map<String, dynamic>) {
    return input['front_default'];
  }
  if (input is String && input.startsWith('https://')) {
    return input;
  }
  return '';
}

/// PokemonApiModel represents the data model for a pokemon as it comes from
/// the server side
@JsonSerializable(explicitToJson: true)
@immutable
class PokemonApiModel {
  const PokemonApiModel({
    this.abilities = const [],
    this.baseExperience = 0,
    this.height = 0,
    this.id = 0,
    this.isDefault = false,
    this.moves = const [],
    this.name = '',
    this.order = 0,
    this.image = '',
    this.types = const [],
    this.weight = 0,
  });

  final List<AbilityInfo> abilities;
  @JsonKey(name: 'base_experience')
  final int baseExperience;
  final int height;
  final int id;
  @JsonKey(name: 'is_default')
  final bool isDefault; // isDefault is a property not used by the UI layer
  final List<MoveInfo> moves;
  final String name;
  final int order;
  @JsonKey(name: 'sprites', fromJson: _extractImage)
  final String image;
  final List<TypeInfo> types;
  final int weight;

  factory PokemonApiModel.fromJson(Map<String, dynamic> json) =>
      _$PokemonApiModelFromJson(json);
  Map<String, dynamic> toJson() => _$PokemonApiModelToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PokemonApiModel &&
          runtimeType == other.runtimeType &&
          listEquals(abilities, other.abilities) &&
          baseExperience == other.baseExperience &&
          height == other.height &&
          id == other.id &&
          isDefault == other.isDefault &&
          listEquals(moves, other.moves) &&
          name == other.name &&
          order == other.order &&
          image == other.image &&
          listEquals(types, other.types) &&
          weight == other.weight;

  @override
  int get hashCode =>
      abilities.hashCode ^
      baseExperience.hashCode ^
      height.hashCode ^
      id.hashCode ^
      isDefault.hashCode ^
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

@JsonSerializable(explicitToJson: true)
@immutable
class AbilityInfo {
  const AbilityInfo(this.ability);
  final Ability ability;
  factory AbilityInfo.fromJson(Map<String, dynamic> json) =>
      _$AbilityInfoFromJson(json);
  Map<String, dynamic> toJson() => _$AbilityInfoToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AbilityInfo &&
          runtimeType == other.runtimeType &&
          ability == other.ability;

  @override
  int get hashCode => ability.hashCode;
}

@JsonSerializable()
@immutable
class Ability {
  const Ability(this.name);
  final String name;
  factory Ability.fromJson(Map<String, dynamic> json) =>
      _$AbilityFromJson(json);
  Map<String, dynamic> toJson() => _$AbilityToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Ability &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;
}

@JsonSerializable(explicitToJson: true)
@immutable
class MoveInfo {
  const MoveInfo(this.move);
  final Move move;
  factory MoveInfo.fromJson(Map<String, dynamic> json) =>
      _$MoveInfoFromJson(json);
  Map<String, dynamic> toJson() => _$MoveInfoToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoveInfo &&
          runtimeType == other.runtimeType &&
          move == other.move;

  @override
  int get hashCode => move.hashCode;
}

@JsonSerializable()
@immutable
class Move {
  const Move(this.name);
  final String name;
  factory Move.fromJson(Map<String, dynamic> json) => _$MoveFromJson(json);
  Map<String, dynamic> toJson() => _$MoveToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Move && runtimeType == other.runtimeType && name == other.name;

  @override
  int get hashCode => name.hashCode;
}

@JsonSerializable(explicitToJson: true)
@immutable
class TypeInfo {
  const TypeInfo(this.type);
  final Type type;
  factory TypeInfo.fromJson(Map<String, dynamic> json) =>
      _$TypeInfoFromJson(json);
  Map<String, dynamic> toJson() => _$TypeInfoToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TypeInfo &&
          runtimeType == other.runtimeType &&
          type == other.type;

  @override
  int get hashCode => type.hashCode;
}

@JsonSerializable()
@immutable
class Type {
  const Type(this.name);
  final String name;
  factory Type.fromJson(Map<String, dynamic> json) => _$TypeFromJson(json);
  Map<String, dynamic> toJson() => _$TypeToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Type && runtimeType == other.runtimeType && name == other.name;

  @override
  int get hashCode => name.hashCode;
}
