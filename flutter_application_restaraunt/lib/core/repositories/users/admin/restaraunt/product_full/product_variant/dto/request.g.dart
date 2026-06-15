// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductVariantCreateDTO _$ProductVariantCreateDTOFromJson(
        Map<String, dynamic> json) =>
    ProductVariantCreateDTO(
      name: json['name'] as String,
      price: (json['price'] as num).toInt(),
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      value: (json['value'] as num?)?.toInt(),
      unit: json['unit'] as String?,
      sku: json['sku'] as String,
      isAvailable: json['is_available'] as bool,
      isCombo: json['is_combo'] as bool,
      productId: (json['product_id'] as num).toInt(),
    );

Map<String, dynamic> _$ProductVariantCreateDTOToJson(
        ProductVariantCreateDTO instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'price': instance.price,
      'image_url': instance.imageUrl,
      'value': instance.value,
      'unit': instance.unit,
      'sku': instance.sku,
      'is_available': instance.isAvailable,
      'is_combo': instance.isCombo,
    };

ProductVariantPatchDTO _$ProductVariantPatchDTOFromJson(
        Map<String, dynamic> json) =>
    ProductVariantPatchDTO(
      name: json['name'] as String?,
      price: (json['price'] as num?)?.toInt(),
      imageUrl: json['image_url'] as String?,
      value: (json['value'] as num?)?.toInt(),
      unit: json['unit'] as String?,
      sku: json['sku'] as String?,
      isAvailable: json['is_available'] as bool?,
      isCombo: json['is_combo'] as bool?,
      productId: (json['product_id'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ProductVariantPatchDTOToJson(
    ProductVariantPatchDTO instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('name', instance.name);
  writeNotNull('price', instance.price);
  writeNotNull('image_url', instance.imageUrl);
  writeNotNull('value', instance.value);
  writeNotNull('unit', instance.unit);
  writeNotNull('sku', instance.sku);
  writeNotNull('is_available', instance.isAvailable);
  writeNotNull('is_combo', instance.isCombo);
  writeNotNull('product_id', instance.productId);
  return val;
}
