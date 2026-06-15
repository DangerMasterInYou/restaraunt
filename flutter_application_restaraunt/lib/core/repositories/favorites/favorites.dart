import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '/api_config.dart';
import '/core/repositories/services/jwt_tokens/jwt_tokens.dart';

class FavoriteItemDTO {
  final int id;
  final int productVariantId;
  final int quantity;
  final List<int> modifierIds;
  final String? productName;
  final String? variantName;
  final String? imageUrl;
  final List<String> modifierNames;
  final int price;

  const FavoriteItemDTO({
    required this.id,
    required this.productVariantId,
    required this.quantity,
    required this.modifierIds,
    required this.modifierNames,
    required this.price,
    this.productName,
    this.variantName,
    this.imageUrl,
  });

  String? get fullImageUrl {
    final url = imageUrl;
    if (url == null || url.isEmpty) return null;
    return url.startsWith('http') ? url : '${ApiConfig.apiSiteUrl}$url';
  }

  factory FavoriteItemDTO.fromJson(Map<String, dynamic> json) =>
      FavoriteItemDTO(
        id: (json['id'] as num).toInt(),
        productVariantId: (json['product_variant_id'] as num).toInt(),
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        modifierIds: ((json['modifier_ids'] as List?) ?? const [])
            .map((e) => (e as num).toInt())
            .toList(),
        modifierNames: ((json['modifier_names'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        price: (json['price'] as num?)?.toInt() ?? 0,
        productName: json['product_name'] as String?,
        variantName: json['variant_name'] as String?,
        imageUrl: json['image_url'] as String?,
      );
}

class FavoriteGroupDTO {
  final int id;
  final String name;
  final List<FavoriteItemDTO> items;

  const FavoriteGroupDTO({
    required this.id,
    required this.name,
    required this.items,
  });

  factory FavoriteGroupDTO.fromJson(Map<String, dynamic> json) =>
      FavoriteGroupDTO(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String? ?? '',
        items: ((json['items'] as List?) ?? const [])
            .map((e) => FavoriteItemDTO.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

abstract class AbstractFavoritesRepository {
  Future<List<FavoriteGroupDTO>> listGroups();
  Future<FavoriteGroupDTO> createGroup(String name);
  Future<FavoriteGroupDTO> renameGroup(int groupId, String name);
  Future<void> deleteGroup(int groupId);
  Future<FavoriteGroupDTO> addItem(
    int groupId, {
    required int productVariantId,
    int quantity,
    List<int> modifierIds,
  });
  Future<void> removeItem(int itemId);
  Future<int> addGroupToCart(int groupId);
}

class FavoritesRepository implements AbstractFavoritesRepository {
  FavoritesRepository({required this.dio, required this.apiSiteUrl});

  final Dio dio;
  final String apiSiteUrl;

  static String? get _token =>
      GetIt.I<AbstractJWTTokensRepository>().getAccessToken();

  Options get _authOptions =>
      Options(headers: {'Authorization': 'Bearer $_token'});

  @override
  Future<List<FavoriteGroupDTO>> listGroups() async {
    try {
      final r = await dio.get('$apiSiteUrl/favorites/groups',
          options: _authOptions);
      return (r.data as List<dynamic>)
          .map((e) => FavoriteGroupDTO.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      GetIt.I<Talker>().handle(e, st);
      rethrow;
    }
  }

  @override
  Future<FavoriteGroupDTO> createGroup(String name) async {
    final r = await dio.post('$apiSiteUrl/favorites/groups',
        data: {'name': name}, options: _authOptions);
    return FavoriteGroupDTO.fromJson(r.data as Map<String, dynamic>);
  }

  @override
  Future<FavoriteGroupDTO> renameGroup(int groupId, String name) async {
    final r = await dio.patch('$apiSiteUrl/favorites/groups/$groupId',
        data: {'name': name}, options: _authOptions);
    return FavoriteGroupDTO.fromJson(r.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteGroup(int groupId) async {
    await dio.delete('$apiSiteUrl/favorites/groups/$groupId',
        options: _authOptions);
  }

  @override
  Future<FavoriteGroupDTO> addItem(
    int groupId, {
    required int productVariantId,
    int quantity = 1,
    List<int> modifierIds = const [],
  }) async {
    final r = await dio.post(
      '$apiSiteUrl/favorites/groups/$groupId/items',
      data: {
        'product_variant_id': productVariantId,
        'quantity': quantity,
        'modifier_ids': modifierIds,
      },
      options: _authOptions,
    );
    return FavoriteGroupDTO.fromJson(r.data as Map<String, dynamic>);
  }

  @override
  Future<void> removeItem(int itemId) async {
    await dio.delete('$apiSiteUrl/favorites/groups/items/$itemId',
        options: _authOptions);
  }

  @override
  Future<int> addGroupToCart(int groupId) async {
    final r = await dio.post('$apiSiteUrl/favorites/groups/$groupId/to-cart',
        options: _authOptions);
    final data = r.data as Map<String, dynamic>;
    return (data['added'] as num?)?.toInt() ?? 0;
  }
}
