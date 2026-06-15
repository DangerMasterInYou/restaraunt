// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CategoryCreateDTO _$CategoryCreateDTOFromJson(Map<String, dynamic> json) =>
    CategoryCreateDTO(
      name: json['name'] as String,
      sortOrder: (json['sort_order'] as num).toInt(),
    );

Map<String, dynamic> _$CategoryCreateDTOToJson(CategoryCreateDTO instance) =>
    <String, dynamic>{
      'name': instance.name,
      'sort_order': instance.sortOrder,
    };

CategoryPatchDTO _$CategoryPatchDTOFromJson(Map<String, dynamic> json) =>
    CategoryPatchDTO(
      name: json['name'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt(),
    );

Map<String, dynamic> _$CategoryPatchDTOToJson(CategoryPatchDTO instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('name', instance.name);
  writeNotNull('sort_order', instance.sortOrder);
  return val;
}
