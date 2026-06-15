import 'package:dio/dio.dart';

import 'package:get_it/get_it.dart';
import 'package:talker_flutter/talker_flutter.dart';
import '../modifier_group_association.dart';

class ModifierGroupAssociationRepository
    implements AbstractModifierGroupAssociationRepository {
  ModifierGroupAssociationRepository({
    required this.dio,
    required this.apiSiteUrl,
  });

  final Dio dio;
  final String apiSiteUrl;
  static String? get token =>
      GetIt.I<AbstractJWTTokensRepository>().getAccessToken();

  @override
  Future<void> linkGroupToVariant(int variantId, int groupId) async {
    try {
      final response = await dio.post(
        '$apiSiteUrl/admin/link/variants/$variantId/groups/$groupId',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      );
      if (response.statusCode != 200 &&
          response.statusCode != 201 &&
          response.statusCode != 204) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message:
              'Ошибка при привязке группы к варианту: ${response.statusCode}',
        );
      }
    } catch (e, st) {
      GetIt.instance<Talker>().handle(e, st);
      throw Exception('Ошибка при привязке группы к варианту: $e');
    }
  }

  @override
  Future<void> unlinkGroupFromVariant(int variantId, int groupId) async {
    try {
      final response = await dio.delete(
        '$apiSiteUrl/admin/link/variants/$variantId/groups/$groupId',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      );
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message:
              'Ошибка при отвязке группы от варианта: ${response.statusCode}',
        );
      }
    } catch (e, st) {
      GetIt.instance<Talker>().handle(e, st);
      throw Exception('Ошибка при отвязке группы от варианта: $e');
    }
  }

  Options get _auth => Options(
        headers: {'Authorization': 'Bearer $token'},
        receiveTimeout: const Duration(seconds: 5),
        sendTimeout: const Duration(seconds: 5),
      );

  @override
  Future<void> linkGroupToProduct(int productId, int groupId) async {
    try {
      await dio.post(
        '$apiSiteUrl/admin/link/products/$productId/groups/$groupId',
        options: _auth,
      );
    } catch (e, st) {
      GetIt.instance<Talker>().handle(e, st);
      throw Exception('Ошибка при привязке группы к продукту: $e');
    }
  }

  @override
  Future<void> unlinkGroupFromProduct(int productId, int groupId) async {
    try {
      await dio.delete(
        '$apiSiteUrl/admin/link/products/$productId/groups/$groupId',
        options: _auth,
      );
    } catch (e, st) {
      GetIt.instance<Talker>().handle(e, st);
      throw Exception('Ошибка при отвязке группы от продукта: $e');
    }
  }
}
