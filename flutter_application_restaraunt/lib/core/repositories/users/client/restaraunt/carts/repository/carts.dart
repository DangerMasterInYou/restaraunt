
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:talker_flutter/talker_flutter.dart';
import '../carts.dart';

class CartRepository implements AbstractCartRepository {
  CartRepository({required this.dio, required this.apiSiteUrl});

  final Dio dio;
  final String apiSiteUrl;

  static String? get _token =>
      GetIt.I<AbstractJWTTokensRepository>().getAccessToken();
  Options get _authOptions =>
      Options(headers: {'Authorization': 'Bearer $_token'});

  @override
  Future<CartResponseDTO> getCart() async {
    try {
      final response = await dio.get('$apiSiteUrl/cart', options: _authOptions);
      return CartResponseDTO.fromJson(response.data);
    } on DioException catch (e, st) {
      GetIt.I<Talker>().handle(e, st);
      rethrow;
    }
  }

  @override
  Future<CartResponseDTO> addItemToCart(CartItemRequestDTO item) async {
    try {
      final response = await dio.post(
        '$apiSiteUrl/cart/items',
        data: item.toJson(),
        options: _authOptions,
      );
      return CartResponseDTO.fromJson(response.data);
    } on DioException catch (e, st) {
      GetIt.I<Talker>().handle(e, st);
      rethrow;
    }
  }

  @override
  Future<CartResponseDTO> updateItemQuantity(
      int cartItemId, int newQuantity) async {
    try {
      final response = await dio.patch(
        '$apiSiteUrl/cart/items/$cartItemId',
        data: {'quantity': newQuantity},
        options: _authOptions,
      );
      return CartResponseDTO.fromJson(response.data);
    } on DioException catch (e, st) {
      GetIt.I<Talker>().handle(e, st);
      rethrow;
    }
  }

  @override
  Future<CartResponseDTO> deleteItemFromCart(int cartItemId) async {
    try {
      final response = await dio.delete(
        '$apiSiteUrl/cart/items/$cartItemId',
        options: _authOptions,
      );
      return CartResponseDTO.fromJson(response.data);
    } on DioException catch (e, st) {
      GetIt.I<Talker>().handle(e, st);
      rethrow;
    }
  }
}
