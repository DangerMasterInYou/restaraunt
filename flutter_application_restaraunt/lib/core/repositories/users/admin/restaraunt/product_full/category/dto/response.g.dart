// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CategoryResponse _$CategoryResponseFromJson(Map<String, dynamic> json) =>
    CategoryResponse(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      sortOrder: (json['sort_order'] as num).toInt(),
      isDeleted: json['is_deleted'] as bool,
    );

Map<String, dynamic> _$CategoryResponseToJson(CategoryResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'sort_order': instance.sortOrder,
      'is_deleted': instance.isDeleted,
    };
