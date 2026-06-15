// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductCreateDTO _$ProductCreateDTOFromJson(Map<String, dynamic> json) =>
    ProductCreateDTO(
      categoryId: (json['category_id'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String?,
      sortOrder: (json['sort_order'] as num).toInt(),
      imageUrl: json['image_url'] as String,
    );

Map<String, dynamic> _$ProductCreateDTOToJson(ProductCreateDTO instance) =>
    <String, dynamic>{
      'category_id': instance.categoryId,
      'name': instance.name,
      'description': instance.description,
      'sort_order': instance.sortOrder,
      'image_url': instance.imageUrl,
    };

ProductPatchDTO _$ProductPatchDTOFromJson(Map<String, dynamic> json) =>
    ProductPatchDTO(
      categoryId: (json['category_id'] as num?)?.toInt(),
      name: json['name'] as String?,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ProductPatchDTOToJson(ProductPatchDTO instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('category_id', instance.categoryId);
  writeNotNull('name', instance.name);
  writeNotNull('description', instance.description);
  writeNotNull('image_url', instance.imageUrl);
  writeNotNull('sort_order', instance.sortOrder);
  return val;
}
