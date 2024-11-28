// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pokemon_api_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PokemonApiModel _$PokemonApiModelFromJson(Map<String, dynamic> json) =>
    PokemonApiModel(
      abilities: (json['abilities'] as List<dynamic>?)
              ?.map((e) => AbilityInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      baseExperience: json['base_experience'] as int? ?? 0,
      height: json['height'] as int? ?? 0,
      id: json['id'] as int? ?? 0,
      isDefault: json['is_default'] as bool? ?? false,
      moves: (json['moves'] as List<dynamic>?)
              ?.map((e) => MoveInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      name: json['name'] as String? ?? '',
      order: json['order'] as int? ?? 0,
      image: json['sprites'] == null
          ? ''
          : _extractImage(json['sprites'] as Object),
      types: (json['types'] as List<dynamic>?)
              ?.map((e) => TypeInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      weight: json['weight'] as int? ?? 0,
    );

Map<String, dynamic> _$PokemonApiModelToJson(PokemonApiModel instance) =>
    <String, dynamic>{
      'abilities': instance.abilities.map((e) => e.toJson()).toList(),
      'base_experience': instance.baseExperience,
      'height': instance.height,
      'id': instance.id,
      'is_default': instance.isDefault,
      'moves': instance.moves.map((e) => e.toJson()).toList(),
      'name': instance.name,
      'order': instance.order,
      'sprites': instance.image,
      'types': instance.types.map((e) => e.toJson()).toList(),
      'weight': instance.weight,
    };

AbilityInfo _$AbilityInfoFromJson(Map<String, dynamic> json) => AbilityInfo(
      Ability.fromJson(json['ability'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AbilityInfoToJson(AbilityInfo instance) =>
    <String, dynamic>{
      'ability': instance.ability.toJson(),
    };

Ability _$AbilityFromJson(Map<String, dynamic> json) => Ability(
      json['name'] as String,
    );

Map<String, dynamic> _$AbilityToJson(Ability instance) => <String, dynamic>{
      'name': instance.name,
    };

MoveInfo _$MoveInfoFromJson(Map<String, dynamic> json) => MoveInfo(
      Move.fromJson(json['move'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MoveInfoToJson(MoveInfo instance) => <String, dynamic>{
      'move': instance.move.toJson(),
    };

Move _$MoveFromJson(Map<String, dynamic> json) => Move(
      json['name'] as String,
    );

Map<String, dynamic> _$MoveToJson(Move instance) => <String, dynamic>{
      'name': instance.name,
    };

TypeInfo _$TypeInfoFromJson(Map<String, dynamic> json) => TypeInfo(
      Type.fromJson(json['type'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TypeInfoToJson(TypeInfo instance) => <String, dynamic>{
      'type': instance.type.toJson(),
    };

Type _$TypeFromJson(Map<String, dynamic> json) => Type(
      json['name'] as String,
    );

Map<String, dynamic> _$TypeToJson(Type instance) => <String, dynamic>{
      'name': instance.name,
    };
