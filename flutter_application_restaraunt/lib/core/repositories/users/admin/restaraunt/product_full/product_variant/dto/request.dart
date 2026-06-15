import 'package:json_annotation/json_annotation.dart';

part 'request.g.dart';

@JsonSerializable()
class ProductVariantCreateDTO{
  const ProductVariantCreateDTO._({
    required this.name,
    required this.price,
    this.description,
    this.imageUrl,
    this.value,
    this.unit,
    required this.sku,
    required this.isAvailable,
    required this.isCombo,
    required this.productId,
  });

  factory ProductVariantCreateDTO({
    required String name,
    required int price,
    String? description,
    String? imageUrl,
    int? value,
    String? unit,
    required String sku,
    required bool isAvailable,
    required bool isCombo,
    required int productId,
  }) {
    return ProductVariantCreateDTO._(
      name: name,
      description: description,
      price: price,
      imageUrl: imageUrl,
      value: value,
      unit: unit,
      sku: sku,
      isAvailable: isAvailable,
      isCombo: isCombo,
      productId: productId,
    );
  }

  @JsonKey(name: 'name')
  final String name;

  @JsonKey(name: 'description')
  final String? description;

  @JsonKey(name: 'price')
  final int price;

  @JsonKey(name: 'image_url')
  final String? imageUrl;

  @JsonKey(name: 'value')
  final int? value;

  @JsonKey(name: 'unit')
  final String? unit;

  @JsonKey(name: 'sku')
  final String sku;

  @JsonKey(name: 'is_available')
  final bool isAvailable;

  @JsonKey(name: 'is_combo')
  final bool isCombo;

  @JsonKey(name: 'product_id', includeToJson: false)
  final int productId;

  factory ProductVariantCreateDTO.fromJson(Map<String, dynamic> json) =>
      _$ProductVariantCreateDTOFromJson(json);
  Map<String, dynamic> toJson() => _$ProductVariantCreateDTOToJson(this);
}

@JsonSerializable()
class ProductVariantPatchDTO {
  @JsonKey(name: 'name', includeIfNull: false)
  final String? name;

  @JsonKey(name: 'price', includeIfNull: false)
  final int? price;

  @JsonKey(name: 'image_url', includeIfNull: false)
  final String? imageUrl;

  @JsonKey(name: 'value', includeIfNull: false)
  final int? value;

  @JsonKey(name: 'unit', includeIfNull: false)
  final String? unit;

  @JsonKey(name: 'sku', includeIfNull: false)
  final String? sku;

  @JsonKey(name: 'is_available', includeIfNull: false)
  final bool? isAvailable;

  @JsonKey(name: 'is_combo', includeIfNull: false)
  final bool? isCombo;

  @JsonKey(name: 'product_id', includeIfNull: false)
  final int? productId;

  ProductVariantPatchDTO({
    this.name,
    this.price,
    this.imageUrl,
    this.value,
    this.unit,
    this.sku,
    this.isAvailable,
    this.isCombo,
    this.productId,
  });

  factory ProductVariantPatchDTO.fromJson(Map<String, dynamic> json) =>
      _$ProductVariantPatchDTOFromJson(json);

  Map<String, dynamic> toJson() => _$ProductVariantPatchDTOToJson(this);
}
