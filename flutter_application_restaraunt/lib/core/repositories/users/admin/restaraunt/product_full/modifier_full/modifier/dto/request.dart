import 'package:json_annotation/json_annotation.dart';

part 'request.g.dart';

@JsonSerializable()
class ModifierCreateDTO {
  const ModifierCreateDTO._({
    required this.name,
    required this.priceDelta,
    this.imageUrl,
  });

  factory ModifierCreateDTO({
    required String name,
    required int priceDelta,
    String? imageUrl,
  }) {
    return ModifierCreateDTO._(
      name: name,
      priceDelta: priceDelta,
      imageUrl: imageUrl,
    );
  }

  @JsonKey(name: 'name')
  final String name;

  @JsonKey(name: 'price_delta')
  final int priceDelta;

  @JsonKey(name: 'image_url', includeIfNull: false)
  final String? imageUrl;

  factory ModifierCreateDTO.fromJson(Map<String, dynamic> json) =>
      _$ModifierCreateDTOFromJson(json);
  Map<String, dynamic> toJson() => _$ModifierCreateDTOToJson(this);
}

@JsonSerializable()
class ModifierPatchDTO {
  @JsonKey(name: 'name', includeIfNull: false)
  final String? name;

  @JsonKey(name: 'price_delta', includeIfNull: false)
  final int? priceDelta;

  @JsonKey(name: 'image_url', includeIfNull: false)
  final String? imageUrl;

  ModifierPatchDTO({
    this.name,
    this.priceDelta,
    this.imageUrl,
  });

  factory ModifierPatchDTO.fromJson(Map<String, dynamic> json) =>
      _$ModifierPatchDTOFromJson(json);

  Map<String, dynamic> toJson() => _$ModifierPatchDTOToJson(this);
}
