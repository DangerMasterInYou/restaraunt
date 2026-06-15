import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:talker_flutter/talker_flutter.dart';
import '../combo_bundle.dart';

class ComboBundleRepository implements AbstractComboBundleRepository {
  ComboBundleRepository({
    required this.dio,
    required this.apiSiteUrl,
  });

  final Dio dio;
  final String apiSiteUrl;

  static String? get token =>
      GetIt.I<AbstractJWTTokensRepository>().getAccessToken();

  @override
  Future<List<ComboBundleResponse>> getComboBundleList() async {
    try {
      return await _fetchComboBundleListFromApi();
    } catch (e, st) {
      GetIt.instance<Talker>().handle(e, st);
      throw Exception('Ошибка при получении списка комбо-бандлов: $e');
    }
  }

  Future<List<ComboBundleResponse>> _fetchComboBundleListFromApi() async {
    try {
      final response = await dio.get(
        '$apiSiteUrl/combo_bundles',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      );

      if (response.statusCode != 200) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Ошибка при загрузке данных: ${response.statusCode}',
        );
      }

      final data = response.data;
      if (data is! List) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Неожиданный формат ответа',
        );
      }

      return data.map<ComboBundleResponse>((item) {
        return ComboBundleResponse.fromJson(item);
      }).toList();
    } on DioException catch (e) {
      GetIt.instance<Talker>().handle(e, e.stackTrace);
      rethrow;
    }
  }

  @override
  Future<ComboBundleResponse> getComboBundle(int comboBundleId) async {
    try {
      return await _fetchComboBundleFromApi(comboBundleId);
    } catch (e, st) {
      GetIt.instance<Talker>().handle(e, st);
      throw Exception('Ошибка при получении комбо-бандла: $e');
    }
  }

  Future<ComboBundleResponse> _fetchComboBundleFromApi(int comboBundleId) async {
    try {
      final response = await dio.get(
        '$apiSiteUrl/combo_bundles/$comboBundleId',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      );

      if (response.statusCode != 200) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Ошибка при загрузке данных: ${response.statusCode}',
        );
      }

      return ComboBundleResponse.fromJson(response.data);
    } on DioException catch (e) {
      GetIt.instance<Talker>().handle(e, e.stackTrace);
      rethrow;
    }
  }

  @override
  Future<ComboBundleResponse> postCreateComboBundle(
      ComboBundleCreateDTO dto) async {
    try {
      return await _fetchCreatedComboBundleFromApi(dto);
    } catch (e, st) {
      GetIt.instance<Talker>().handle(e, st);
      throw Exception('Ошибка при создании комбо-бандла: $e');
    }
  }

  Future<ComboBundleResponse> _fetchCreatedComboBundleFromApi(
      ComboBundleCreateDTO dto) async {
    final response = await dio.post(
      '$apiSiteUrl/admin/combo_bundles',
      data: dto.toJson(),
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
        contentType: Headers.jsonContentType,
        receiveTimeout: const Duration(seconds: 5),
        sendTimeout: const Duration(seconds: 5),
      ),
    );

    if (response.statusCode != 201) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Ошибка создания: ${response.statusCode}',
      );
    }

    return ComboBundleResponse.fromJson(response.data);
  }

  @override
  Future<ComboBundleResponse> patchComboBundle(
      int comboBundleId, ComboBundlePatchDTO dto) async {
    try {
      return await _fetchUpdatedComboBundleFromApi(comboBundleId, dto);
    } catch (e, st) {
      GetIt.instance<Talker>().handle(e, st);
      throw Exception('Ошибка при обновлении комбо-бандла: $e');
    }
  }

  Future<ComboBundleResponse> _fetchUpdatedComboBundleFromApi(
      int comboBundleId, ComboBundlePatchDTO dto) async {
    final response = await dio.patch(
      '$apiSiteUrl/admin/combo_bundles/$comboBundleId',
      data: dto.toJson(),
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
        contentType: Headers.jsonContentType,
        receiveTimeout: const Duration(seconds: 5),
        sendTimeout: const Duration(seconds: 5),
      ),
    );

    if (response.statusCode != 200) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Ошибка обновления: ${response.statusCode}',
      );
    }

    return ComboBundleResponse.fromJson(response.data);
  }

  @override
  Future<void> deleteHardComboBundle(int comboBundleId) async {
    try {
      await _deleteHardComboBundleViaApi(comboBundleId);
    } catch (e, st) {
      GetIt.instance<Talker>().handle(e, st);
      throw Exception('Ошибка жесткого удаления: $e');
    }
  }

  Future<void> _deleteHardComboBundleViaApi(int comboBundleId) async {
    final response = await dio.delete(
      '$apiSiteUrl/admin/combo_bundles/$comboBundleId/hard',
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
        receiveTimeout: const Duration(seconds: 5),
        sendTimeout: const Duration(seconds: 5),
      ),
    );

    if (response.statusCode != 204) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Ошибка удаления: ${response.statusCode}',
      );
    }
  }

  @override
  Future<void> deleteSoftComboBundle(int comboBundleId) async {
    try {
      await _deleteSoftComboBundleViaApi(comboBundleId);
    } catch (e, st) {
      GetIt.instance<Talker>().handle(e, st);
      throw Exception('Ошибка мягкого удаления: $e');
    }
  }

  Future<void> _deleteSoftComboBundleViaApi(int comboBundleId) async {
    final response = await dio.delete(
      '$apiSiteUrl/admin/combo_bundles/$comboBundleId/soft',
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
        receiveTimeout: const Duration(seconds: 5),
        sendTimeout: const Duration(seconds: 5),
      ),
    );

    if (response.statusCode != 204) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Ошибка удаления: ${response.statusCode}',
      );
    }
  }

  @override
  Future<void> postRestoreComboBundle(int comboBundleId) async {
    try {
      await _restoreComboBundleViaApi(comboBundleId);
    } catch (e, st) {
      GetIt.instance<Talker>().handle(e, st);
      throw Exception('Ошибка восстановления: $e');
    }
  }

  Future<void> _restoreComboBundleViaApi(int comboBundleId) async {
    final response = await dio.post(
      '$apiSiteUrl/admin/combo_bundles/$comboBundleId/restore',
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
        receiveTimeout: const Duration(seconds: 5),
        sendTimeout: const Duration(seconds: 5),
      ),
    );

    if (response.statusCode != 204) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Ошибка восстановления: ${response.statusCode}',
      );
    }
  }
}