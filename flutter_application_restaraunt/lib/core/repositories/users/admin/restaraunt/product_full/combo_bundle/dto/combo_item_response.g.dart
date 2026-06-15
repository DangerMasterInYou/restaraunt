// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'combo_item_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ComboItemVariantDTO _$ComboItemVariantDTOFromJson(Map<String, dynamic> json) =>
    ComboItemVariantDTO(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      price: (json['price'] as num).toInt(),
    );

Map<String, dynamic> _$ComboItemVariantDTOToJson(
        ComboItemVariantDTO instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'price': instance.price,
    };

ComboItemResponse _$ComboItemResponseFromJson(Map<String, dynamic> json) =>
    ComboItemResponse(
      quantity: (json['quantity'] as num).toInt(),
      includedVariant: ComboItemVariantDTO.fromJson(
          json['included_variant'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ComboItemResponseToJson(ComboItemResponse instance) =>
    <String, dynamic>{
      'quantity': instance.quantity,
      'included_variant': instance.includedVariant,
    };

ComboItemCreateDTO _$ComboItemCreateDTOFromJson(Map<String, dynamic> json) =>
    ComboItemCreateDTO(
      includedVariantId: (json['included_variant_id'] as num).toInt(),
      quantity: (json['quantity'] as num).toInt(),
    );

Map<String, dynamic> _$ComboItemCreateDTOToJson(ComboItemCreateDTO instance) =>
    <String, dynamic>{
      'included_variant_id': instance.includedVariantId,
      'quantity': instance.quantity,
    };
