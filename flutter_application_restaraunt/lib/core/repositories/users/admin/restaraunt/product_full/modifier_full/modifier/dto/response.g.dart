// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ModifierResponse _$ModifierResponseFromJson(Map<String, dynamic> json) =>
    ModifierResponse(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      priceDelta: (json['price_delta'] as num).toInt(),
      groupId: (json['group_id'] as num).toInt(),
      imageUrl: json['image_url'] as String?,
      isDeleted: json['is_deleted'] as bool? ?? false,
    );

Map<String, dynamic> _$ModifierResponseToJson(ModifierResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'price_delta': instance.priceDelta,
      'group_id': instance.groupId,
      'image_url': instance.imageUrl,
      'is_deleted': instance.isDeleted,
    };
