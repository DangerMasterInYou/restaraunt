import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../profile.dart';
import '/core/repositories/services/jwt_tokens/abstract_jwt_tokens_repository.dart';

class ProfileRepository implements AbstractProfileRepository {
  ProfileRepository({
    required this.dio,
    required this.apiSiteUrl,
  });

  final Dio dio;
  final String apiSiteUrl;

  static String? get _token =>
      GetIt.I<AbstractJWTTokensRepository>().getAccessToken();

  @override
  Future<ProfileResponse> getProfile() async {
    try {
      final response = await dio.get(
        '$apiSiteUrl/profile',
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
          message: 'Ошибка получения профиля: ${response.statusCode}',
        );
      }
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Неверный формат ответа профиля',
        );
      }
      return ProfileResponse.fromJson(data);
    } on DioException catch (e) {
      GetIt.instance<Talker>().handle(e, e.stackTrace);
      rethrow;
    } catch (e, st) {
      GetIt.instance<Talker>().handle(e, st);
      throw Exception('Не удалось получить профиль: $e');
    }
  }

  @override
  Future<void> patchProfile(ProfilePatchDTO patchDto) async {
    try {
      final response = await dio.patch(
        '$apiSiteUrl/profile',
        data: patchDto.toJson(),
        options: Options(
          headers: {'Authorization': 'Bearer $_token'},
          contentType: Headers.jsonContentType,
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      );
      if (response.statusCode != 200) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Ошибка обновления профиля: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      GetIt.instance<Talker>().handle(e, e.stackTrace);
      rethrow;
    } catch (e, st) {
      GetIt.instance<Talker>().handle(e, st);
      throw Exception('Не удалось обновить профиль: $e');
    }
  }

  @override
  Future<void> deleteProfile() async {
    try {
      final response = await dio.delete(
        '$apiSiteUrl/profile',
        options: Options(
          headers: {'Authorization': 'Bearer $_token'},
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      );
      if (response.statusCode != 204 && response.statusCode != 200) {

        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Ошибка удаления профиля: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      GetIt.instance<Talker>().handle(e, e.stackTrace);
      rethrow;
    } catch (e, st) {
      GetIt.instance<Talker>().handle(e, st);
      throw Exception('Не удалось удалить профиль: $e');
    }
  }
}
