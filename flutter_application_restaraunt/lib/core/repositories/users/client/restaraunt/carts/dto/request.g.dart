// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppliedModifierCreateDTO _$AppliedModifierCreateDTOFromJson(
        Map<String, dynamic> json) =>
    AppliedModifierCreateDTO(
      modifierId: (json['modifier_id'] as num).toInt(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$AppliedModifierCreateDTOToJson(
        AppliedModifierCreateDTO instance) =>
    <String, dynamic>{
      'modifier_id': instance.modifierId,
      'quantity': instance.quantity,
    };

CartItemRequestDTO _$CartItemRequestDTOFromJson(Map<String, dynamic> json) =>
    CartItemRequestDTO(
      productVariantId: (json['product_variant_id'] as num).toInt(),
      quantity: (json['quantity'] as num).toInt(),
      modifiers: (json['modifiers'] as List<dynamic>?)
              ?.map((e) =>
                  AppliedModifierCreateDTO.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$CartItemRequestDTOToJson(CartItemRequestDTO instance) =>
    <String, dynamic>{
      'product_variant_id': instance.productVariantId,
      'quantity': instance.quantity,
      'modifiers': instance.modifiers,
    };
