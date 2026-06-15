import 'package:json_annotation/json_annotation.dart';

part 'request.g.dart';

@JsonSerializable()
class ProfilePatchDTO {
  @JsonKey(name: 'birthday', includeIfNull: false)
  final DateTime? birthday;

  @JsonKey(name: 'first_name', includeIfNull: false)
  final String? firstName;

  @JsonKey(name: 'last_name', includeIfNull: false)
  final String? lastName;

  @JsonKey(name: 'phone', includeIfNull: false)
  final String? phone;

  ProfilePatchDTO({
    this.birthday,
    this.firstName,
    this.lastName,
    this.phone,
  });

  factory ProfilePatchDTO.fromJson(Map<String, dynamic> json) =>
      _$ProfilePatchDTOFromJson(json);

  Map<String, dynamic> toJson() => _$ProfilePatchDTOToJson(this);
}
