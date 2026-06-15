import 'package:dio/dio.dart';

import 'package:get_it/get_it.dart';
import 'package:talker_flutter/talker_flutter.dart';
import '../modifier_group.dart';

class ModifierGroupRepository implements AbstractModifierGroupRepository {
  ModifierGroupRepository({
    required this.dio,
    required this.apiSiteUrl,
  });

  final Dio dio;
  final String apiSiteUrl;
  static String? get token =>
      GetIt.I<AbstractJWTTokensRepository>().getAccessToken();

  @override
  Future<List<ModifierGroupResponse>> getModifierGroupList() async {
    try {
      return await _fetchModifierGroupListFromApi();
    } catch (e, st) {
      GetIt.instance<Talker>().handle(e, st);
      throw Exception('Ошибка загрузки списка групп модификаторов: $e');
    }
  }

  Future<List<ModifierGroupResponse>> _fetchModifierGroupListFromApi() async {
    try {
      final response = await dio.get(
        '$apiSiteUrl/admin/modifier-groups',
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
      final modifierGroupList = data.map((item) {
        if (item is! Map<String, dynamic>) {
          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            message: 'Неверный формат данных группы модификаторов',
          );
        }
        try {
          final modifierGroup = ModifierGroupResponse.fromJson(item);
          return modifierGroup;
        } catch (e) {
          rethrow;
        }
      }).toList();
      return List<ModifierGroupResponse>.from(modifierGroupList);
    } on DioException catch (e) {
      GetIt.instance<Talker>().handle(e, e.stackTrace);
      rethrow;
    } catch (e, st) {
      GetIt.instance<Talker>().handle(e, st);
      throw Exception('Ошибка при получении списка групп модификаторов: $e');
    }
  }

  @override
  Future<ModifierGroupResponse> getModifierGroup(int modifierGroupId) async {
    try {
      return await _fetchModifierGroupFromApi(modifierGroupId);
    } catch (e, st) {
      GetIt.instance<Talker>().handle(e, st);
      throw Exception('Ошибка при получении группы модификаторов: $e');
    }
  }

  Future<ModifierGroupResponse> _fetchModifierGroupFromApi(
      int modifierGroupId) async {
    try {
      final response = await dio.get(
        '$apiSiteUrl/admin/modifier-groups/$modifierGroupId',
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
      final modifierGroupData = response.data;
      if (modifierGroupData is! Map<String, dynamic>) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message:
              'Неожиданный формат ответа для группы модификаторов $modifierGroupId',
        );
      }
      final modifierGroup = ModifierGroupResponse.fromJson(modifierGroupData);
      return modifierGroup;
    } catch (e) {
      throw Exception('Ошибка при получении группы модификаторов: $e');
    }
  }

  @override
  Future<ModifierGroupResponse> postCreateModifierGroup(
      ModifierGroupCreateDTO dto) async {
    try {
      final modifierGroup = await _fetchCreatedModifierGroupFromApi(dto);
      return modifierGroup;
    } catch (e, st) {
      GetIt.instance<Talker>().handle(e, st);
      throw Exception('Ошибка при создании группы модификаторов: $e');
    }
  }

  Future<ModifierGroupResponse> _fetchCreatedModifierGroupFromApi(
      ModifierGroupCreateDTO dto) async {
    final response = await dio.post(
      '$apiSiteUrl/admin/modifier-groups',
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

    return ModifierGroupResponse.fromJson(response.data);
  }

  @override
  Future<ModifierGroupResponse> patchModifierGroup(
      int modifierGroupId, ModifierGroupPatchDTO dto) async {
    try {
      final modifierGroup =
          await _fetchUpdatedModifierGroupFromApi(modifierGroupId, dto);
      return modifierGroup;
    } catch (e, st) {
      GetIt.instance<Talker>().handle(e, st);
      throw Exception('Ошибка при обновлении группы модификаторов: $e');
    }
  }

  Future<ModifierGroupResponse> _fetchUpdatedModifierGroupFromApi(
      int modifierGroupId, ModifierGroupPatchDTO dto) async {
    final response = await dio.patch(
      '$apiSiteUrl/admin/modifier-groups/$modifierGroupId',
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

    return ModifierGroupResponse.fromJson(response.data);
  }

  @override
  Future<void> deleteHardModifierGroup(int modifierGroupId) async {
    try {
      await _deleteHardModifierGroupViaApi(modifierGroupId);
    } catch (e, st) {
      GetIt.instance<Talker>().handle(e, st);
      throw Exception('Ошибка жесткого удаления: $e');
    }
  }

  Future<void> _deleteHardModifierGroupViaApi(int modifierGroupId) async {
    final response = await dio.delete(
      '$apiSiteUrl/admin/modifier-groups/$modifierGroupId/hard',
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
  Future<void> deleteSoftModifierGroup(int modifierGroupId) async {
    try {
      await _deleteSoftModifierGroupViaApi(modifierGroupId);
    } catch (e, st) {
      GetIt.instance<Talker>().handle(e, st);
      throw Exception('Ошибка мягкого удаления: $e');
    }
  }

  Future<void> _deleteSoftModifierGroupViaApi(int modifierGroupId) async {
    final response = await dio.delete(
      '$apiSiteUrl/admin/modifier-groups/$modifierGroupId/soft',
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
  Future<void> postRestoreModifierGroup(int modifierGroupId) async {
    try {
      await _restoreModifierGroupViaApi(modifierGroupId);
    } catch (e, st) {
      GetIt.instance<Talker>().handle(e, st);
      throw Exception('Ошибка восстановления группы модификаторов: $e');
    }
  }

  Future<void> _restoreModifierGroupViaApi(int modifierGroupId) async {
    final response = await dio.post(
      '$apiSiteUrl/admin/modifier-groups/$modifierGroupId/restore',
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
