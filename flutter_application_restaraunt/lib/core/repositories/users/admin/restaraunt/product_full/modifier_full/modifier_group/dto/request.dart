import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'request.g.dart';

@JsonSerializable()
class ModifierGroupCreateDTO extends Equatable {
  const ModifierGroupCreateDTO._({
    required this.name,
    required this.isRequired,
    required this.isMultiselect,
  });

  factory ModifierGroupCreateDTO({
    required String name,
    required bool isRequired,
    required bool isMultiselect,
  }) {
    return ModifierGroupCreateDTO._(
      name: name,
      isRequired: isRequired,
      isMultiselect: isMultiselect,
    );
  }

  @JsonKey(name: 'name')
  final String name;

  @JsonKey(name: 'is_required')
  final bool isRequired;

  @JsonKey(name: 'is_multiselect')
  final bool isMultiselect;

  factory ModifierGroupCreateDTO.fromJson(Map<String, dynamic> json) =>
      _$ModifierGroupCreateDTOFromJson(json);
  Map<String, dynamic> toJson() => _$ModifierGroupCreateDTOToJson(this);

  @override
  List<Object> get props => [];
}

@JsonSerializable()
class ModifierGroupPatchDTO {
  @JsonKey(name: 'name', includeIfNull: false)
  final String? name;

  @JsonKey(name: 'is_required', includeIfNull: false)
  final bool? isRequired;

  @JsonKey(name: 'is_multiselect', includeIfNull: false)
  final bool? isMultiselect;

  ModifierGroupPatchDTO({
    this.name,
    this.isRequired,
    this.isMultiselect,
  });

  factory ModifierGroupPatchDTO.fromJson(Map<String, dynamic> json) =>
      _$ModifierGroupPatchDTOFromJson(json);

  Map<String, dynamic> toJson() => _$ModifierGroupPatchDTOToJson(this);
}
