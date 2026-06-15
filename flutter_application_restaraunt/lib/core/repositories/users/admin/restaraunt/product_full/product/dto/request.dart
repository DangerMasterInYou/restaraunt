import 'package:json_annotation/json_annotation.dart';

part 'request.g.dart';

@JsonSerializable()
class ProductCreateDTO{
  const ProductCreateDTO._({
    required this.categoryId,
    required this.name,
    this.description,
    required this.sortOrder,
    required this.imageUrl,
  });

  factory ProductCreateDTO({
    required int categoryId,
    required String name,
    String? description,
    required int sortOrder,
    required String imageUrl,
  }) {
    return ProductCreateDTO._(
      categoryId: categoryId,
      name: name,
      description: description,
      sortOrder: sortOrder,
      imageUrl: imageUrl,
    );
  }

  @JsonKey(name: 'category_id')
  final int categoryId;

  @JsonKey(name: 'name')
  final String name;

  @JsonKey(name: 'description')
  final String? description;

  @JsonKey(name: 'sort_order')
  final int sortOrder;

  @JsonKey(name: 'image_url')
  final String imageUrl;

  factory ProductCreateDTO.fromJson(Map<String, dynamic> json) =>
      _$ProductCreateDTOFromJson(json);
  Map<String, dynamic> toJson() => _$ProductCreateDTOToJson(this);
}

@JsonSerializable()
class ProductPatchDTO {
  @JsonKey(name: 'category_id', includeIfNull: false)
  final int? categoryId;

  @JsonKey(name: 'name', includeIfNull: false)
  final String? name;

  @JsonKey(name: 'description', includeIfNull: false)
  final String? description;

  @JsonKey(name: 'image_url', includeIfNull: false)
  final String? imageUrl;

  @JsonKey(name: 'sort_order', includeIfNull: false)
  final int? sortOrder;

  ProductPatchDTO({
    this.categoryId,
    this.name,
    this.description,
    this.imageUrl,
    this.sortOrder,
  });

  factory ProductPatchDTO.fromJson(Map<String, dynamic> json) =>
      _$ProductPatchDTOFromJson(json);

  Map<String, dynamic> toJson() => _$ProductPatchDTOToJson(this);
}
