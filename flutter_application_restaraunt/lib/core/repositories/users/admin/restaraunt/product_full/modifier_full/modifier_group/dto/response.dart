import 'package:json_annotation/json_annotation.dart';

part 'response.g.dart';

@JsonSerializable()
class ModifierInGroupDto {
  const ModifierInGroupDto({
    required this.name,
    required this.priceDelta,
    this.id,
    this.imageUrl,
  });

  final int? id;
  final String name;

  @JsonKey(name: 'price_delta')
  final int priceDelta;

  @JsonKey(name: 'image_url')
  final String? imageUrl;

  factory ModifierInGroupDto.fromJson(Map<String, dynamic> json) =>
      _$ModifierInGroupDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ModifierInGroupDtoToJson(this);
}

@JsonSerializable()
class ModifierGroupResponse {
  const ModifierGroupResponse({
    required this.id,
    required this.name,
    required this.isRequired,
    required this.isMultiselect,
    required this.isDeleted,
    required this.modifiers,
  });

  final int id;
  final String name;

  @JsonKey(name: 'is_required')
  final bool isRequired;

  @JsonKey(name: 'is_multiselect')
  final bool isMultiselect;

  @JsonKey(name: 'is_deleted')
  final bool isDeleted;

  final List<ModifierInGroupDto> modifiers;

  factory ModifierGroupResponse.fromJson(Map<String, dynamic> json) {
    final rawModifiers = json['modifiers'] as List<dynamic>?;

    return ModifierGroupResponse(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      isRequired: json['is_required'] as bool? ?? false,
      isMultiselect: json['is_multiselect'] as bool? ?? true,
      isDeleted: json['is_deleted'] as bool? ?? false,
      modifiers: rawModifiers != null
          ? rawModifiers
              .map(
                  (e) => ModifierInGroupDto.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() => _$ModifierGroupResponseToJson(this);
}
