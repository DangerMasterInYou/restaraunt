import 'package:json_annotation/json_annotation.dart';

part 'request.g.dart';

@JsonSerializable()
class ComboBundleCreateDTO {
  const ComboBundleCreateDTO({
    required this.comboVariantId,
    required this.includedVariantIds,
    required this.quantity,
  });

  @JsonKey(name: 'combo_variant_id')
  final int comboVariantId;

  @JsonKey(name: 'included_variant_ids')
  final List<int> includedVariantIds;

  @JsonKey(name: 'quantity')
  final int quantity;

  factory ComboBundleCreateDTO.fromJson(Map<String, dynamic> json) =>
      _$ComboBundleCreateDTOFromJson(json);

  Map<String, dynamic> toJson() => _$ComboBundleCreateDTOToJson(this);
}

@JsonSerializable()
class ComboBundlePatchDTO {
  @JsonKey(name: 'combo_variant_id', includeIfNull: false)
  final int? comboVariantId;

  @JsonKey(name: 'included_variant_ids', includeIfNull: false)
  final List<int>? includedVariantIds;

  @JsonKey(name: 'quantity', includeIfNull: false)
  final int? quantity;

  const ComboBundlePatchDTO({
    this.comboVariantId,
    this.includedVariantIds,
    this.quantity,
  });

  factory ComboBundlePatchDTO.fromJson(Map<String, dynamic> json) =>
      _$ComboBundlePatchDTOFromJson(json);

  Map<String, dynamic> toJson() => _$ComboBundlePatchDTOToJson(this);
}
