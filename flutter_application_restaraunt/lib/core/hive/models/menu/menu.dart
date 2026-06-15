import 'package:flutter_application_restaraunt/api_config.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:json_annotation/json_annotation.dart';
import '../header_boxes.dart';

part 'menu.g.dart';

@HiveType(typeId: HiveHeaders.menuId)
@JsonSerializable()
class Menu {
  @HiveField(0)
  final int id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String? description;
  @HiveField(3)
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  String get fullImageUrl => '${ApiConfig.apiSiteUrl}$imageUrl';
  @HiveField(4)
  final String category;
  @HiveField(5)
  final int price;
  @HiveField(6)
  final int? value;
  @HiveField(7)
  final String? unit;
  @HiveField(8)
  final String sku;
  @HiveField(9)
  @JsonKey(name: 'is_available')
  final bool isAvailable;
  @HiveField(10)
  @JsonKey(name: 'is_deleted')
  final bool? isDeleted;
  @HiveField(11)
  @JsonKey(name: 'modifier_groups')
  final List<ModifierGroup> modifierGroups;

  @HiveField(12)
  @JsonKey(name: 'product_id')
  final int? productId;

  Menu({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.category,
    required this.price,
    this.value,
    this.unit,
    required this.sku,
    required this.isAvailable,
    this.isDeleted = false,
    required this.modifierGroups,
    this.productId,
  });

  factory Menu.fromJson(Map<String, dynamic> json) => _$MenuFromJson(json);
  Map<String, dynamic> toJson() => _$MenuToJson(this);
}

@HiveType(typeId: HiveHeaders.modifierGroupId)
@JsonSerializable()
class ModifierGroup {
  @HiveField(0)
  final int id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  @JsonKey(name: 'is_required')
  final bool isRequired;
  @HiveField(3)
  @JsonKey(name: 'is_multiselect')
  final bool isMultiselect;
  @HiveField(4)
  @JsonKey(name: 'is_deleted')
  final bool isDeleted;
  @HiveField(5)
  final List<Modifier> modifiers;

  ModifierGroup({
    required this.id,
    required this.name,
    required this.isRequired,
    required this.isMultiselect,
    this.isDeleted = false,
    required this.modifiers,
  });

  factory ModifierGroup.fromJson(Map<String, dynamic> json) {
    return ModifierGroup(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      isRequired: json['is_required'] as bool? ?? false,
      isMultiselect: json['is_multiselect'] as bool? ?? false,
      isDeleted: json['is_deleted'] as bool? ?? false,

      modifiers: (json['modifiers'] as List<dynamic>?)
              ?.map((e) => Modifier.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => _$ModifierGroupToJson(this);
}

@HiveType(typeId: HiveHeaders.modifierId)
@JsonSerializable()
class Modifier {
  @HiveField(0)
  final int id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  @JsonKey(name: 'price_delta')
  final int priceDelta;
  @HiveField(3)
  @JsonKey(name: 'image_url')
  final String? imageUrl;

  Modifier({
    required this.id,
    required this.name,
    required this.priceDelta,
    this.imageUrl,
  });

  String? get fullImageUrl {
    if (imageUrl == null || imageUrl!.isEmpty) return null;
    return imageUrl!.startsWith('http')
        ? imageUrl
        : '${ApiConfig.apiSiteUrl}$imageUrl';
  }

  factory Modifier.fromJson(Map<String, dynamic> json) {
    return Modifier(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      priceDelta: (json['price_delta'] as num?)?.toInt() ?? 0,
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => _$ModifierToJson(this);
}
