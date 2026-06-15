import 'package:json_annotation/json_annotation.dart';

part 'response.g.dart';

@JsonSerializable()
class CategoryResponse
{
  const CategoryResponse({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.isDeleted,
  });

  final int id;

  final String name;

  @JsonKey(name: 'sort_order')
  final int sortOrder;

  @JsonKey(name: 'is_deleted')
  final bool isDeleted;

  factory CategoryResponse.fromJson(Map<String, dynamic> json) =>
      _$CategoryResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryResponseToJson(this);
}
