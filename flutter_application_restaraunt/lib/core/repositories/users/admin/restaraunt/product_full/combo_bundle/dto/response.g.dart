// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ComboBundleResponse _$ComboBundleResponseFromJson(Map<String, dynamic> json) =>
    ComboBundleResponse(
      id: (json['id'] as num).toInt(),
      comboVariant:
          Menu.fromJson(json['combo_variant'] as Map<String, dynamic>),
      includedVariants: (json['included_variants'] as List<dynamic>)
          .map((e) => Menu.fromJson(e as Map<String, dynamic>))
          .toList(),
      quantity: (json['quantity'] as num).toInt(),
      isDeleted: json['is_deleted'] as bool,
    );

Map<String, dynamic> _$ComboBundleResponseToJson(
        ComboBundleResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'combo_variant': instance.comboVariant,
      'included_variants': instance.includedVariants,
      'quantity': instance.quantity,
      'is_deleted': instance.isDeleted,
    };
