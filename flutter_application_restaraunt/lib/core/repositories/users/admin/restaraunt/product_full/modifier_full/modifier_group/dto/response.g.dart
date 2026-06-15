// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ModifierInGroupDto _$ModifierInGroupDtoFromJson(Map<String, dynamic> json) =>
    ModifierInGroupDto(
      name: json['name'] as String,
      priceDelta: (json['price_delta'] as num).toInt(),
      id: (json['id'] as num?)?.toInt(),
      imageUrl: json['image_url'] as String?,
    );

Map<String, dynamic> _$ModifierInGroupDtoToJson(ModifierInGroupDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'price_delta': instance.priceDelta,
      'image_url': instance.imageUrl,
    };

ModifierGroupResponse _$ModifierGroupResponseFromJson(
        Map<String, dynamic> json) =>
    ModifierGroupResponse(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      isRequired: json['is_required'] as bool,
      isMultiselect: json['is_multiselect'] as bool,
      isDeleted: json['is_deleted'] as bool,
      modifiers: (json['modifiers'] as List<dynamic>)
          .map((e) => ModifierInGroupDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ModifierGroupResponseToJson(
        ModifierGroupResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'is_required': instance.isRequired,
      'is_multiselect': instance.isMultiselect,
      'is_deleted': instance.isDeleted,
      'modifiers': instance.modifiers,
    };
