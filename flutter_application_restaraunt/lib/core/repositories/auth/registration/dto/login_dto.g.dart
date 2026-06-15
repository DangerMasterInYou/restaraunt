// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginDTO _$LoginDTOFromJson(Map<String, dynamic> json) => LoginDTO(
      firstName: (json['firstName'] as num).toInt(),
      lastName: json['lastName'] as String,
      address: json['address'] as String,
      birthday: DateTime.parse(json['birthday'] as String),
      email: json['email'] as String,
    );

Map<String, dynamic> _$LoginDTOToJson(LoginDTO instance) => <String, dynamic>{
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'address': instance.address,
      'birthday': instance.birthday.toIso8601String(),
      'email': instance.email,
    };
