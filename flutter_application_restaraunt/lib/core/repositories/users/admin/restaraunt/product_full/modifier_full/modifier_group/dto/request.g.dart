// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ModifierGroupCreateDTO _$ModifierGroupCreateDTOFromJson(
        Map<String, dynamic> json) =>
    ModifierGroupCreateDTO(
      name: json['name'] as String,
      isRequired: json['is_required'] as bool,
      isMultiselect: json['is_multiselect'] as bool,
    );

Map<String, dynamic> _$ModifierGroupCreateDTOToJson(
        ModifierGroupCreateDTO instance) =>
    <String, dynamic>{
      'name': instance.name,
      'is_required': instance.isRequired,
      'is_multiselect': instance.isMultiselect,
    };

ModifierGroupPatchDTO _$ModifierGroupPatchDTOFromJson(
        Map<String, dynamic> json) =>
    ModifierGroupPatchDTO(
      name: json['name'] as String?,
      isRequired: json['is_required'] as bool?,
      isMultiselect: json['is_multiselect'] as bool?,
    );

Map<String, dynamic> _$ModifierGroupPatchDTOToJson(
    ModifierGroupPatchDTO instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('name', instance.name);
  writeNotNull('is_required', instance.isRequired);
  writeNotNull('is_multiselect', instance.isMultiselect);
  return val;
}
