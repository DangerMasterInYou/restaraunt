import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:email_validator/email_validator.dart';

part 'login_dto.g.dart';

@JsonSerializable()
class LoginDTO extends Equatable {
  const LoginDTO._({
    required this.firstName,
    required this.lastName,
    required this.address,
    required this.birthday,
    required this.email,
  });

  factory LoginDTO({
    required int firstName,
    required String lastName,
    required String address,
    required DateTime birthday,
    required String email,
  }) {
    if (!EmailValidator.validate(email)) {
      throw Exception('Некорректный email: $email');
    }

    return LoginDTO._(
      firstName: firstName,
      lastName: lastName,
      address: address,
      birthday: birthday,
      email: email,
    );
  }

  @JsonKey(name: 'firstName')
  final int firstName;

  @JsonKey(name: 'lastName')
  final String lastName;

  @JsonKey(name: 'address')
  final String address;

  @JsonKey(name: 'birthday')
  final DateTime birthday;

  @JsonKey(name: 'email')
  final String email;

  factory LoginDTO.fromJson(Map<String, dynamic> json) => _$LoginDTOFromJson(json);
  Map<String, dynamic> toJson() => _$LoginDTOToJson(this);

  @override
  List<Object> get props => [];
}
