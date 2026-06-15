// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProfilePatchDTO _$ProfilePatchDTOFromJson(Map<String, dynamic> json) =>
    ProfilePatchDTO(
      birthday: json['birthday'] == null
          ? null
          : DateTime.parse(json['birthday'] as String),
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      phone: json['phone'] as String?,
    );

Map<String, dynamic> _$ProfilePatchDTOToJson(ProfilePatchDTO instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('birthday', instance.birthday?.toIso8601String());
  writeNotNull('first_name', instance.firstName);
  writeNotNull('last_name', instance.lastName);
  writeNotNull('phone', instance.phone);
  return val;
}
