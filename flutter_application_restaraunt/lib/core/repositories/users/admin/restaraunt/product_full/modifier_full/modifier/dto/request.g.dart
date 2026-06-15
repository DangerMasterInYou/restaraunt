// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ModifierCreateDTO _$ModifierCreateDTOFromJson(Map<String, dynamic> json) =>
    ModifierCreateDTO(
      name: json['name'] as String,
      priceDelta: (json['price_delta'] as num).toInt(),
      imageUrl: json['image_url'] as String?,
    );

Map<String, dynamic> _$ModifierCreateDTOToJson(ModifierCreateDTO instance) {
  final val = <String, dynamic>{
    'name': instance.name,
    'price_delta': instance.priceDelta,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('image_url', instance.imageUrl);
  return val;
}

ModifierPatchDTO _$ModifierPatchDTOFromJson(Map<String, dynamic> json) =>
    ModifierPatchDTO(
      name: json['name'] as String?,
      priceDelta: (json['price_delta'] as num?)?.toInt(),
      imageUrl: json['image_url'] as String?,
    );

Map<String, dynamic> _$ModifierPatchDTOToJson(ModifierPatchDTO instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('name', instance.name);
  writeNotNull('price_delta', instance.priceDelta);
  writeNotNull('image_url', instance.imageUrl);
  return val;
}
