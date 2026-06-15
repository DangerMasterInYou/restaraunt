import 'package:json_annotation/json_annotation.dart';

part 'request.g.dart';

@JsonSerializable()
class CategoryCreateDTO {
  const CategoryCreateDTO._({required this.name, required this.sortOrder});

  factory CategoryCreateDTO({required String name, required int sortOrder}) {
    return CategoryCreateDTO._(name: name, sortOrder: sortOrder);
  }

  final String name;

  @JsonKey(name: 'sort_order')
  final int sortOrder;

  factory CategoryCreateDTO.fromJson(Map<String, dynamic> json) =>
      _$CategoryCreateDTOFromJson(json);
  Map<String, dynamic> toJson() => _$CategoryCreateDTOToJson(this);
}

@JsonSerializable()
class CategoryPatchDTO {
  @JsonKey(name: 'name', includeIfNull: false)
  final String? name;

  @JsonKey(name: 'sort_order', includeIfNull: false)
  final int? sortOrder;

  CategoryPatchDTO({
    this.name,
    this.sortOrder,
  });

  factory CategoryPatchDTO.fromJson(Map<String, dynamic> json) =>
      _$CategoryPatchDTOFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryPatchDTOToJson(this);
}
