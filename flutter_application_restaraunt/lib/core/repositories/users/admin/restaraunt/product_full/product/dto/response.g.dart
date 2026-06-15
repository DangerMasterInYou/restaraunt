// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductResponse _$ProductResponseFromJson(Map<String, dynamic> json) =>
    ProductResponse(
      id: (json['id'] as num).toInt(),
      category:
          CategoryResponse.fromJson(json['category'] as Map<String, dynamic>),
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String,
      sortOrder: (json['sort_order'] as num).toInt(),
      isDeleted: json['is_deleted'] as bool,
      variants: (json['variants'] as List<dynamic>)
          .map((e) => VariantResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ProductResponseToJson(ProductResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'category': instance.category,
      'name': instance.name,
      'description': instance.description,
      'image_url': instance.imageUrl,
      'sort_order': instance.sortOrder,
      'is_deleted': instance.isDeleted,
      'variants': instance.variants,
    };
