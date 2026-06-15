import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '/core/repositories/services/jwt_tokens/jwt_tokens.dart';
import '../dto/combo_item_response.dart';

abstract class AbstractComboItemsRepository {
  Future<List<ComboItemResponse>> getComboItems(int comboVariantId);

  Future<void> addComboItem(
    int comboVariantId,
    ComboItemCreateDTO dto,
  );

  Future<void> removeComboItem(
    int comboVariantId,
    int includedVariantId,
  );
}

class ComboItemsRepository implements AbstractComboItemsRepository {
  ComboItemsRepository({required this.dio, required this.apiSiteUrl});

  final Dio dio;
  final String apiSiteUrl;

  static String? get _token =>
      GetIt.I<AbstractJWTTokensRepository>().getAccessToken();

  Options get _authOptions =>
      Options(headers: {'Authorization': 'Bearer $_token'});

  @override
  Future<List<ComboItemResponse>> getComboItems(int comboVariantId) async {
    try {
      final response = await dio.get(
        '$apiSiteUrl/admin/combo/$comboVariantId/items',
        options: _authOptions,
      );
      final data = response.data;
      if (data is! List) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Неожиданный формат состава комбо',
        );
      }
      return data
          .map((item) =>
              ComboItemResponse.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e, st) {
      GetIt.I<Talker>().handle(e, st);
      rethrow;
    }
  }

  @override
  Future<void> addComboItem(
    int comboVariantId,
    ComboItemCreateDTO dto,
  ) async {
    try {
      await dio.post(
        '$apiSiteUrl/admin/combo/$comboVariantId/items',
        data: dto.toJson(),
        options: _authOptions,
      );
    } on DioException catch (e, st) {
      GetIt.I<Talker>().handle(e, st);
      rethrow;
    }
  }

  @override
  Future<void> removeComboItem(
    int comboVariantId,
    int includedVariantId,
  ) async {
    try {
      await dio.delete(
        '$apiSiteUrl/admin/combo/$comboVariantId/items/$includedVariantId',
        options: _authOptions,
      );
    } on DioException catch (e, st) {
      GetIt.I<Talker>().handle(e, st);
      rethrow;
    }
  }
}
