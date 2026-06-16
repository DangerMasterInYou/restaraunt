import 'package:flutter_application_restaraunt/api_config.dart';

import '/core/hive/models/menu/menu.dart';

class MenuItem {
  final String name;
  final String? description;
  final String? imageUrl;
  final String category;
  final String? sku;
  final bool isAvailable;
  final List<ModifierGroup> modifierGroups;
  final List<MenuItemVariant> variants;

  const MenuItem({
    required this.name,
    this.description,
    this.imageUrl,
    required this.category,
    this.sku,
    required this.isAvailable,
    required this.modifierGroups,
    required this.variants,
  });

  String get fullImageUrl => '${ApiConfig.apiSiteUrl}$imageUrl';
}

class MenuItemVariant {
  final int id;
  final String name;
  final int price;
  final int? value;
  final String? unit;
  final bool isDefault;
  final String? imageUrl;

  const MenuItemVariant({
    required this.id,
    required this.name,
    required this.price,
    this.value,
    this.unit,
    this.isDefault = false,
    this.imageUrl,
  });

  String? get fullImageUrl {
    final u = imageUrl;
    if (u == null || u.isEmpty) return null;
    return u.startsWith('http') ? u : '${ApiConfig.apiSiteUrl}$u';
  }
}
