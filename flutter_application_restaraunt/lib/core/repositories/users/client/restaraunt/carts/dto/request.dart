
import 'package:json_annotation/json_annotation.dart';

part 'request.g.dart';

@JsonSerializable()
class AppliedModifierCreateDTO {
  @JsonKey(name: 'modifier_id')
  final int modifierId;

  @JsonKey(name: 'quantity')
  final int quantity;

  const AppliedModifierCreateDTO({
    required this.modifierId,
    this.quantity = 1,
  });

  factory AppliedModifierCreateDTO.fromJson(Map<String, dynamic> json) =>
      _$AppliedModifierCreateDTOFromJson(json);
  Map<String, dynamic> toJson() => _$AppliedModifierCreateDTOToJson(this);
}

@JsonSerializable()
class CartItemRequestDTO {
  @JsonKey(name: 'product_variant_id')
  final int productVariantId;

  @JsonKey(name: 'quantity')
  final int quantity;

  @JsonKey(name: 'modifiers')
  final List<AppliedModifierCreateDTO> modifiers;

  CartItemRequestDTO({
    required this.productVariantId,
    required this.quantity,
    this.modifiers = const [],
  });

  factory CartItemRequestDTO.fromJson(Map<String, dynamic> json) =>
      _$CartItemRequestDTOFromJson(json);
  Map<String, dynamic> toJson() => _$CartItemRequestDTOToJson(this);
}