import 'package:hive_flutter/hive_flutter.dart';
import 'package:json_annotation/json_annotation.dart';

part 'response.g.dart';

@JsonSerializable()
class ProfileResponse {
  ProfileResponse({
    required this.id,
    required this.email,
    required this.birthday,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.isActive,
    required this.createdAt,
    this.role,
  });

  @HiveField(0)
  @JsonKey(name: 'id')
  final int id;

  @HiveField(1)
  @JsonKey(name: 'email')
  final String email;

  @HiveField(2)
  @JsonKey(name: 'birthday')
  final DateTime? birthday;

  @HiveField(3)
  @JsonKey(name: 'first_name')
  final String? firstName;

  @HiveField(4)
  @JsonKey(name: 'last_name')
  final String? lastName;

  @HiveField(5)
  @JsonKey(name: 'phone')
  final String? phone;

  @HiveField(6)
  @JsonKey(name: 'is_active')
  final bool isActive;

  @HiveField(7)
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @HiveField(8)
  @JsonKey(name: 'role')
  final String? role;

  factory ProfileResponse.fromJson(Map<String, dynamic> json) =>
      _$ProfileResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ProfileResponseToJson(this);
}
