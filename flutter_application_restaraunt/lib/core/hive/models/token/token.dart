import 'package:hive_flutter/hive_flutter.dart';
import 'package:json_annotation/json_annotation.dart';
import '../header_boxes.dart';

part 'token.g.dart';

@HiveType(typeId: HiveHeaders.tokensId)
@JsonSerializable()
class Token {
  Token({
    required this.id,
    required this.accessToken,
    required this.refreshToken,
  });

  @HiveField(0)
  @JsonKey(name: 'id')
  final int id;

  @HiveField(1)
  @JsonKey(name: 'access')
  final String accessToken;

  @HiveField(2)
  @JsonKey(name: 'refresh')
  final String refreshToken;

  factory Token.fromJson(Map<String, dynamic> json) => _$TokenFromJson(json);
  Map<String, dynamic> toJson() => _$TokenToJson(this);
}
