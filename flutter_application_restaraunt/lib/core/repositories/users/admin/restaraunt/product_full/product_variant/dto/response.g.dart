// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VariantModifierGroupResponse _$VariantModifierGroupResponseFromJson(
        Map<String, dynamic> json) =>
    VariantModifierGroupResponse(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      isDeleted: json['is_deleted'] as bool,
    );

Map<String, dynamic> _$VariantModifierGroupResponseToJson(
        VariantModifierGroupResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'is_deleted': instance.isDeleted,
    };

VariantResponse _$VariantResponseFromJson(Map<String, dynamic> json) =>
    VariantResponse(
      id: (json['id'] as num).toInt(),
      productId: (json['product_id'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      price: (json['price'] as num).toInt(),
      sku: json['sku'] as String,
      value: (json['value'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      isAvailable: json['is_available'] as bool,
      isDeleted: json['is_deleted'] as bool,
      isCombo: json['is_combo'] as bool,
      modifierGroups: (json['modifier_groups'] as List<dynamic>?)
              ?.map((e) => VariantModifierGroupResponse.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$VariantResponseToJson(VariantResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'product_id': instance.productId,
      'name': instance.name,
      'description': instance.description,
      'image_url': instance.imageUrl,
      'price': instance.price,
      'sku': instance.sku,
      'value': instance.value,
      'unit': instance.unit,
      'is_available': instance.isAvailable,
      'is_deleted': instance.isDeleted,
      'is_combo': instance.isCombo,
      'modifier_groups': instance.modifierGroups,
    };
