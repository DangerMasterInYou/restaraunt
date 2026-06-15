import 'package:json_annotation/json_annotation.dart';
import '../product.dart';
import '/api_config.dart';

part 'response.g.dart';

@JsonSerializable()
class ProductResponse {
  const ProductResponse({
    required this.id,
    required this.category,
    required this.name,
    this.description,
    required this.imageUrl,
    required this.sortOrder,
    required this.isDeleted,
    required this.variants,
  });

  final int id;

  final CategoryResponse category;

  final String name;

  final String? description;

  @JsonKey(name: 'image_url')
  final String imageUrl;

  String get fullImageUrl {
    final u = imageUrl;
    if (u.startsWith('http')) return u;
    final path = u.startsWith('/') ? u : '/$u';
    return '${ApiConfig.apiSiteUrl}$path';
  }

  @JsonKey(name: 'sort_order')
  final int sortOrder;

  @JsonKey(name: 'is_deleted')
  final bool isDeleted;

  final List<VariantResponse> variants;

  factory ProductResponse.fromJson(Map<String, dynamic> json) =>
      _$ProductResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ProductResponseToJson(this);
}
