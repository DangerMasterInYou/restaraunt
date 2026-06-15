import 'package:json_annotation/json_annotation.dart';
import '/api_config.dart';

part 'response.g.dart';

@JsonSerializable()
class VariantModifierGroupResponse {
  const VariantModifierGroupResponse({
    required this.id,
    required this.name,
    required this.isDeleted,
  });

  final int id;
  final String name;

  @JsonKey(name: 'is_deleted')
  final bool isDeleted;

  factory VariantModifierGroupResponse.fromJson(Map<String, dynamic> json) =>
      _$VariantModifierGroupResponseFromJson(json);

  Map<String, dynamic> toJson() => _$VariantModifierGroupResponseToJson(this);
}

@JsonSerializable()
class VariantResponse {
  const VariantResponse({
    required this.id,
    required this.productId,
    required this.name,
    this.description,
    this.imageUrl,
    required this.price,
    required this.sku,
    this.value,
    this.unit,
    required this.isAvailable,
    required this.isDeleted,
    required this.isCombo,
    this.modifierGroups = const [],
  });

  final int id;

  @JsonKey(name: 'product_id')
  final int productId;

  final String name;

  final String? description;

  @JsonKey(name: 'image_url')
  final String? imageUrl;

  final int price;

  final String sku;

  final double? value;

  final String? unit;

  @JsonKey(name: 'is_available')
  final bool isAvailable;

  @JsonKey(name: 'is_deleted')
  final bool isDeleted;

  @JsonKey(name: 'is_combo')
  final bool isCombo;

  @JsonKey(name: 'modifier_groups', defaultValue: <VariantModifierGroupResponse>[])
  final List<VariantModifierGroupResponse> modifierGroups;

  String? get fullImageUrl {
    if (imageUrl == null || imageUrl!.isEmpty) return null;
    final url = imageUrl!;
    if (url.startsWith('http')) return url;

    final path = url.startsWith('/') ? url : '/$url';
    return '${ApiConfig.apiSiteUrl}$path';
  }

  factory VariantResponse.fromJson(Map<String, dynamic> json) =>
      _$VariantResponseFromJson(json);

  Map<String, dynamic> toJson() => _$VariantResponseToJson(this);
}
