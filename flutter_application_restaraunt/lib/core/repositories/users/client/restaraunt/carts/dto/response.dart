import 'package:flutter_application_restaraunt/api_config.dart';
import 'package:json_annotation/json_annotation.dart';
import '/core/hive/models/menu/menu.dart';

part 'response.g.dart';

@JsonSerializable()
class CartResponseDTO {
  @JsonKey(name: 'items')
  final List<CartItemResponseDTO> items;

  @JsonKey(name: 'total_price')
  final int? totalPrice;

  @JsonKey(name: 'subtotal_price')
  final int? subtotalPrice;

  @JsonKey(name: 'discount')
  final int? discount;

  @JsonKey(name: 'applied_promotions', defaultValue: <String>[])
  final List<String> appliedPromotions;

  CartResponseDTO({
    required this.items,
    this.totalPrice,
    this.subtotalPrice,
    this.discount,
    this.appliedPromotions = const [],
  });

  factory CartResponseDTO.fromJson(Map<String, dynamic> json) =>
      _$CartResponseDTOFromJson(json);

  Map<String, dynamic> toJson() => _$CartResponseDTOToJson(this);
}

@JsonSerializable()
class CartProductVariantDTO {
  final int id;

  @JsonKey(name: 'product_id')
  final int productId;

  final String name;
  final String? description;

  @JsonKey(name: 'image_url')
  final String? imageUrl;

  final int? price;
  final String sku;
  final double? value;
  final String? unit;

  @JsonKey(name: 'is_available')
  final bool isAvailable;

  @JsonKey(name: 'is_deleted')
  final bool isDeleted;

  @JsonKey(name: 'is_combo')
  final bool isCombo;

  CartProductVariantDTO({
    required this.id,
    required this.productId,
    required this.name,
    this.description,
    this.imageUrl,
    this.price,
    required this.sku,
    this.value,
    this.unit,
    required this.isAvailable,
    required this.isDeleted,
    required this.isCombo,
  });

  String get fullImageUrl =>
      imageUrl != null ? '${ApiConfig.apiSiteUrl}$imageUrl' : '';

  String? get sizeLabel =>
      value != null && unit != null ? '$value $unit' : null;

  factory CartProductVariantDTO.fromJson(Map<String, dynamic> json) =>
      _$CartProductVariantDTOFromJson(json);

  Map<String, dynamic> toJson() => _$CartProductVariantDTOToJson(this);
}

@JsonSerializable()
class CartItemResponseDTO {
  @JsonKey(name: 'id')
  final int id;

  @JsonKey(name: 'quantity')
  final int quantity;

  @JsonKey(name: 'product_name')
  final String? productName;

  @JsonKey(name: 'product_variant')
  final CartProductVariantDTO productVariant;

  @JsonKey(name: 'applied_modifiers')
  final List<AppliedModifierResponseDTO> appliedModifiers;

  @JsonKey(name: 'subtotal_price')
  final int? subtotalPrice;

  CartItemResponseDTO({
    required this.id,
    required this.quantity,
    this.productName,
    required this.productVariant,
    required this.appliedModifiers,
    this.subtotalPrice,
  });

  factory CartItemResponseDTO.fromJson(Map<String, dynamic> json) =>
      _$CartItemResponseDTOFromJson(json);

  Map<String, dynamic> toJson() => _$CartItemResponseDTOToJson(this);
}

@JsonSerializable()
class AppliedModifierResponseDTO {
  @JsonKey(name: 'quantity')
  final int quantity;

  @JsonKey(name: 'modifier')
  final Modifier modifier;

  AppliedModifierResponseDTO({
    required this.quantity,
    required this.modifier,
  });

  factory AppliedModifierResponseDTO.fromJson(Map<String, dynamic> json) =>
      _$AppliedModifierResponseDTOFromJson(json);

  Map<String, dynamic> toJson() => _$AppliedModifierResponseDTOToJson(this);
}
