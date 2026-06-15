import 'package:json_annotation/json_annotation.dart';

part 'combo_item_response.g.dart';

@JsonSerializable()
class ComboItemVariantDTO {
  const ComboItemVariantDTO({
    required this.id,
    required this.name,
    required this.price,
  });

  final int id;
  final String name;
  final int price;

  factory ComboItemVariantDTO.fromJson(Map<String, dynamic> json) =>
      _$ComboItemVariantDTOFromJson(json);

  Map<String, dynamic> toJson() => _$ComboItemVariantDTOToJson(this);
}

@JsonSerializable()
class ComboItemResponse {
  const ComboItemResponse({
    required this.quantity,
    required this.includedVariant,
  });

  final int quantity;

  @JsonKey(name: 'included_variant')
  final ComboItemVariantDTO includedVariant;

  factory ComboItemResponse.fromJson(Map<String, dynamic> json) =>
      _$ComboItemResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ComboItemResponseToJson(this);
}

@JsonSerializable()
class ComboItemCreateDTO {
  const ComboItemCreateDTO({
    required this.includedVariantId,
    required this.quantity,
  });

  @JsonKey(name: 'included_variant_id')
  final int includedVariantId;

  final int quantity;

  factory ComboItemCreateDTO.fromJson(Map<String, dynamic> json) =>
      _$ComboItemCreateDTOFromJson(json);

  Map<String, dynamic> toJson() => _$ComboItemCreateDTOToJson(this);
}
