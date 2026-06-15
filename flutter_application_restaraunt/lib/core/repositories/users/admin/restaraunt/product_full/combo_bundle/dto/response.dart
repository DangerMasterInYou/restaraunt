import 'package:json_annotation/json_annotation.dart';
import '../combo_bundle.dart';

part 'response.g.dart';

@JsonSerializable()
class ComboBundleResponse{
  const ComboBundleResponse({
    required this.id,
    required this.comboVariant,
    required this.includedVariants,
    required this.quantity,
    required this.isDeleted,
  });

  final int id;

  @JsonKey(name: 'combo_variant')
  final Menu comboVariant;

  @JsonKey(name: 'included_variants')
  final List<Menu> includedVariants;

  final int quantity;

  @JsonKey(name: 'is_deleted')
  final bool isDeleted;

  factory ComboBundleResponse.fromJson(Map<String, dynamic> json) =>
      _$ComboBundleResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ComboBundleResponseToJson(this);

  ComboBundleResponse copyWith({
    int? id,
    Menu? comboVariant,
    List<Menu>? includedVariants,
    int? quantity,
    bool? isDeleted,
  }) {
    return ComboBundleResponse(
      id: id ?? this.id,
      comboVariant: comboVariant ?? this.comboVariant,
      includedVariants: includedVariants ?? this.includedVariants,
      quantity: quantity ?? this.quantity,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}