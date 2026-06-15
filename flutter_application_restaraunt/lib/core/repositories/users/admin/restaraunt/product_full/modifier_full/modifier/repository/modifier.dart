import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:talker_flutter/talker_flutter.dart';
import '../dto/response.dart';
import '../dto/request.dart';
import 'abstract_modifier.dart';
import '../../../../../../../services/jwt_tokens/jwt_tokens.dart';

class ModifierRepository implements AbstractModifierRepository {
  ModifierRepository({required this.dio, required this.apiSiteUrl});

  final Dio dio;
  final String apiSiteUrl;

  static String? get _token =>
      GetIt.I<AbstractJWTTokensRepository>().getAccessToken();

  @override
  Future<List<ModifierResponse>> getModifierList() async {
    try {
      final response = await dio.get(
        '$apiSiteUrl/admin/modifiers',
        options: Options(
          headers: {'Authorization': 'Bearer $_token'},
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      );
      if (response.statusCode != 200) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Ошибка загрузки: ${response.statusCode}',
        );
      }
      final data = response.data as List;
      return data.map((e) => ModifierResponse.fromJson(e)).toList();
    } on DioException catch (e) {
      GetIt.I<Talker>().handle(e, e.stackTrace);
      rethrow;
    } catch (e, st) {
      GetIt.I<Talker>().handle(e, st);
      throw Exception('Ошибка получения списка модификаторов: $e');
    }
  }

  @override
  Future<ModifierResponse> getModifier(int modifierId) async {
    try {
      final response = await dio.get(
        '$apiSiteUrl/admin/modifiers/$modifierId',
        options: Options(
          headers: {'Authorization': 'Bearer $_token'},
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      );
      return ModifierResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Ошибка получения модификатора: $e');
    }
  }

  @override
  Future<ModifierResponse> postCreateModifier(
      int groupId, ModifierCreateDTO dto) async {
    final response = await dio.post(
      '$apiSiteUrl/admin/modifier-groups/$groupId/modifiers',
      data: dto.toJson(),
      options: Options(
        headers: {'Authorization': 'Bearer $_token'},
        contentType: Headers.jsonContentType,
      ),
    );
    return ModifierResponse.fromJson(response.data);
  }

  @override
  Future<ModifierResponse> patchModifier(
      int modifierId, ModifierPatchDTO dto) async {
    final response = await dio.patch(
      '$apiSiteUrl/admin/modifiers/$modifierId',
      data: dto.toJson(),
      options: Options(
        headers: {'Authorization': 'Bearer $_token'},
        contentType: Headers.jsonContentType,
      ),
    );
    return ModifierResponse.fromJson(response.data);
  }

  @override
  Future<void> deleteHardModifier(int modifierId) async {
    await dio.delete(
      '$apiSiteUrl/admin/modifiers/$modifierId/hard',
      options: Options(headers: {'Authorization': 'Bearer $_token'}),
    );
  }

  @override
  Future<void> deleteSoftModifier(int modifierId) async {
    await dio.delete(
      '$apiSiteUrl/admin/modifiers/$modifierId/soft',
      options: Options(headers: {'Authorization': 'Bearer $_token'}),
    );
  }

  @override
  Future<void> postRestoreModifier(int modifierId) async {
    await dio.post(
      '$apiSiteUrl/admin/modifiers/$modifierId/restore',
      options: Options(headers: {'Authorization': 'Bearer $_token'}),
    );
  }
}
