import 'package:dio/dio.dart';

import '../category.dart';

import 'package:get_it/get_it.dart';
import 'package:talker_flutter/talker_flutter.dart';

class CategoriesRepository implements AbstractCategoriesRepository {
  CategoriesRepository({
    required this.dio,
    required this.apiSiteUrl,
  });

  final Dio dio;
  final String apiSiteUrl;
  static String? get token =>
      GetIt.I<AbstractJWTTokensRepository>().getAccessToken();

  @override
  Future<List<CategoryResponse>> getCategoryList() async {
    try {
      final categoryList = await _fetchCategoryListFromApi();
      return categoryList;
    } catch (e, st) {
      GetIt.instance<Talker>().handle(e, st);
      throw Exception('Ошибка при получении списка категорий: $e');
    }
  }

  Future<List<CategoryResponse>> _fetchCategoryListFromApi() async {
    try {
      final response = await dio.get(
        '$apiSiteUrl/admin/categories',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
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
      final categoryList = data.map((item) {
        if (item is! Map<String, dynamic>) {
          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            message: 'Неверный формат данных категории',
          );
        }
        try {
          final category = CategoryResponse.fromJson(item);
          return category;
        } catch (e) {
          rethrow;
        }
      }).toList();
      return List<CategoryResponse>.from(categoryList);
    } on DioException catch (e) {
      GetIt.instance<Talker>().handle(e, e.stackTrace);
      rethrow;
    } catch (e, st) {
      GetIt.instance<Talker>().handle(e, st);
      throw Exception('Ошибка при получении списка категорий: $e');
    }
  }

  @override
  Future<CategoryResponse> getCategory(int categoryId) async {
    try {
      final category = await _fetchCategoryFromApi(categoryId);
      return category;
    } catch (e, st) {
      GetIt.instance<Talker>().handle(e, st);
      throw Exception('Ошибка при получении категории: $e');
    }
  }

  Future<CategoryResponse> _fetchCategoryFromApi(int categoryId) async {
    try {
      final response = await dio.get(
        '$apiSiteUrl/admin/categories/$categoryId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
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
      final categoryData = response.data;
      if (categoryData is! Map<String, dynamic>) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Неожиданный формат ответа для категории $categoryId',
        );
      }
      final category = CategoryResponse.fromJson(categoryData);
      return category;
    } catch (e) {
      throw Exception('Ошибка при получении категории: $e');
    }
  }

  @override
  Future<void> reorderCategories(List<int> ids) async {
    await dio.post(
      '$apiSiteUrl/admin/categories/reorder',
      data: {'ids': ids},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  @override
  Future<CategoryResponse> postCreateCategory(CategoryCreateDTO dto) async {
    try {
      final category = await _fetchCreatedCategoryFromApi(dto);
      return category;
    } catch (e, st) {
      GetIt.instance<Talker>().handle(e, st);
      throw Exception('Ошибка при создании категории: $e');
    }
  }

  Future<CategoryResponse> _fetchCreatedCategoryFromApi(
      CategoryCreateDTO dto) async {
    final response = await dio.post(
      '$apiSiteUrl/admin/categories',
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

    return CategoryResponse.fromJson(response.data);
  }

  @override
  Future<CategoryResponse> patchCategory(
      int categoryId, CategoryPatchDTO dto) async {
    try {
      final category = await _fetchUpdatedCategoryFromApi(categoryId, dto);
      return category;
    } catch (e, st) {
      GetIt.instance<Talker>().handle(e, st);
      throw Exception('Ошибка при обновлении категории: $e');
    }
  }

  Future<CategoryResponse> _fetchUpdatedCategoryFromApi(
      int categoryId, CategoryPatchDTO dto) async {
    final response = await dio.patch(
      '$apiSiteUrl/admin/categories/$categoryId',
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

    return CategoryResponse.fromJson(response.data);
  }

  @override
  Future<void> deleteHardCategory(int categoryId) async {
    try {
      await _deleteHardCategoryViaApi(categoryId);
    } catch (e, st) {
      GetIt.instance<Talker>().handle(e, st);
      throw Exception('Ошибка жесткого удаления: $e');
    }
  }

  Future<void> _deleteHardCategoryViaApi(int categoryId) async {
    final response = await dio.delete(
      '$apiSiteUrl/admin/categories/$categoryId/hard',
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
  Future<void> deleteSoftCategory(int categoryId) async {
    try {
      await _deleteSoftCategoryViaApi(categoryId);
    } catch (e, st) {
      GetIt.instance<Talker>().handle(e, st);
      throw Exception('Ошибка мягкого удаления: $e');
    }
  }

  Future<void> _deleteSoftCategoryViaApi(int categoryId) async {
    final response = await dio.delete(
      '$apiSiteUrl/admin/categories/$categoryId/soft',
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
  Future<void> postRestoreCategory(int categoryId) async {
    try {
      await _restoreCategoryViaApi(categoryId);
    } catch (e, st) {
      GetIt.instance<Talker>().handle(e, st);
      throw Exception('Ошибка восстановления категории: $e');
    }
  }

  Future<void> _restoreCategoryViaApi(int categoryId) async {
    final response = await dio.post(
      '$apiSiteUrl/admin/categories/$categoryId/restore',
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
