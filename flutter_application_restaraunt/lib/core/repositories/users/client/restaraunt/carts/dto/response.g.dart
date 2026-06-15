// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CartResponseDTO _$CartResponseDTOFromJson(Map<String, dynamic> json) =>
    CartResponseDTO(
      items: (json['items'] as List<dynamic>)
          .map((e) => CartItemResponseDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalPrice: (json['total_price'] as num?)?.toInt(),
      subtotalPrice: (json['subtotal_price'] as num?)?.toInt(),
      discount: (json['discount'] as num?)?.toInt(),
      appliedPromotions: (json['applied_promotions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );

Map<String, dynamic> _$CartResponseDTOToJson(CartResponseDTO instance) =>
    <String, dynamic>{
      'items': instance.items,
      'total_price': instance.totalPrice,
      'subtotal_price': instance.subtotalPrice,
      'discount': instance.discount,
      'applied_promotions': instance.appliedPromotions,
    };

CartProductVariantDTO _$CartProductVariantDTOFromJson(
        Map<String, dynamic> json) =>
    CartProductVariantDTO(
      id: (json['id'] as num).toInt(),
      productId: (json['product_id'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      price: (json['price'] as num?)?.toInt(),
      sku: json['sku'] as String,
      value: (json['value'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      isAvailable: json['is_available'] as bool,
      isDeleted: json['is_deleted'] as bool,
      isCombo: json['is_combo'] as bool,
    );

Map<String, dynamic> _$CartProductVariantDTOToJson(
        CartProductVariantDTO instance) =>
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
    };

CartItemResponseDTO _$CartItemResponseDTOFromJson(Map<String, dynamic> json) =>
    CartItemResponseDTO(
      id: (json['id'] as num).toInt(),
      quantity: (json['quantity'] as num).toInt(),
      productName: json['product_name'] as String?,
      productVariant: CartProductVariantDTO.fromJson(
          json['product_variant'] as Map<String, dynamic>),
      appliedModifiers: (json['applied_modifiers'] as List<dynamic>)
          .map((e) =>
              AppliedModifierResponseDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
      subtotalPrice: (json['subtotal_price'] as num?)?.toInt(),
    );

Map<String, dynamic> _$CartItemResponseDTOToJson(
        CartItemResponseDTO instance) =>
    <String, dynamic>{
      'id': instance.id,
      'quantity': instance.quantity,
      'product_name': instance.productName,
      'product_variant': instance.productVariant,
      'applied_modifiers': instance.appliedModifiers,
      'subtotal_price': instance.subtotalPrice,
    };

AppliedModifierResponseDTO _$AppliedModifierResponseDTOFromJson(
        Map<String, dynamic> json) =>
    AppliedModifierResponseDTO(
      quantity: (json['quantity'] as num).toInt(),
      modifier: Modifier.fromJson(json['modifier'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AppliedModifierResponseDTOToJson(
        AppliedModifierResponseDTO instance) =>
    <String, dynamic>{
      'quantity': instance.quantity,
      'modifier': instance.modifier,
    };
