// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProfileResponse _$ProfileResponseFromJson(Map<String, dynamic> json) =>
    ProfileResponse(
      id: (json['id'] as num).toInt(),
      email: json['email'] as String,
      birthday: json['birthday'] == null
          ? null
          : DateTime.parse(json['birthday'] as String),
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      phone: json['phone'] as String?,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      role: json['role'] as String?,
    );

Map<String, dynamic> _$ProfileResponseToJson(ProfileResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'birthday': instance.birthday?.toIso8601String(),
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'phone': instance.phone,
      'is_active': instance.isActive,
      'created_at': instance.createdAt.toIso8601String(),
      'role': instance.role,
    };
