import 'package:dio/dio.dart';

import '../product.dart';

import 'package:get_it/get_it.dart';
import 'package:talker_flutter/talker_flutter.dart';

class ProductRepository implements AbstractProductRepository {
  ProductRepository({
    required this.dio,
    required this.apiSiteUrl,
  });

  final Dio dio;
  final String apiSiteUrl;
  static String? get token =>
      GetIt.I<AbstractJWTTokensRepository>().getAccessToken();

  @override
  Future<void> reorderProducts(List<int> ids) async {
    await dio.post(
      '$apiSiteUrl/admin/products/reorder',
      data: {'ids': ids},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  @override
  Future<List<ProductResponse>> getProductList() async {
    try {
      final productsList = await _fetchProductListFromApi();
      return productsList;
    } catch (e, st) {
      GetIt.instance<Talker>().handle(e, st);
      throw Exception('Ошибка при получении списка продуктов: $e');
    }
  }

  Future<List<ProductResponse>> _fetchProductListFromApi() async {
    try {
      final response = await dio.get(
        '$apiSiteUrl/admin/products',
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
      final productsList = data.map((item) {
        if (item is! Map<String, dynamic>) {
          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            message: 'Неверный формат данных продукта',
          );
        }
        try {
          final product = ProductResponse.fromJson(item);
          return product;
        } catch (e) {
          rethrow;
        }
      }).toList();
      return List<ProductResponse>.from(productsList);
    } on DioException catch (e) {
      GetIt.instance<Talker>().handle(e, e.stackTrace);
      rethrow;
    } catch (e, st) {
      GetIt.instance<Talker>().handle(e, st);
      throw Exception('Ошибка при получении списка продуктов: $e');
    }
  }

  @override
  Future<ProductResponse> getProduct(int productId) async {
    try {
      final product = await _fetchProductFromApi(productId);
      return product;
    } catch (e, st) {
      GetIt.instance<Talker>().handle(e, st);
      throw Exception('Ошибка при получении продукта: $e');
    }
  }

  Future<ProductResponse> _fetchProductFromApi(int productId) async {
    try {
      final response = await dio.get(
        '$apiSiteUrl/admin/products/$productId',
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
      final productData = response.data;
      if (productData is! Map<String, dynamic>) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Неожиданный формат ответа для продукта $productId',
        );
      }
      final product = ProductResponse.fromJson(productData);
      return product;
    } catch (e) {
      throw Exception('Ошибка при получении продукта: $e');
    }
  }

  @override
  Future<ProductResponse> postCreateProduct(ProductCreateDTO dto) async {
    try {
      final product = await _fetchCreatedProductFromApi(dto);
      return product;
    } catch (e, st) {
      GetIt.instance<Talker>().handle(e, st);
      throw Exception('Ошибка при создании продукта: $e');
    }
  }

  Future<ProductResponse> _fetchCreatedProductFromApi(
      ProductCreateDTO dto) async {
    final response = await dio.post(
      '$apiSiteUrl/admin/products',
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

    return ProductResponse.fromJson(response.data);
  }

  @override
  Future<ProductResponse> patchProduct(
      int productId, ProductPatchDTO dto) async {
    try {
      final product = await _fetchUpdatedProductFromApi(productId, dto);
      return product;
    } catch (e, st) {
      GetIt.instance<Talker>().handle(e, st);
      throw Exception('Ошибка при обновлении продукта: $e');
    }
  }

  Future<ProductResponse> _fetchUpdatedProductFromApi(
      int productId, ProductPatchDTO dto) async {
    final response = await dio.patch(
      '$apiSiteUrl/admin/products/$productId',
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

    return ProductResponse.fromJson(response.data);
  }

  @override
  Future<void> deleteHardProduct(int productId) async {
    try {
      await _deleteHardProductViaApi(productId);
    } catch (e, st) {
      GetIt.instance<Talker>().handle(e, st);
      throw Exception('Ошибка жесткого удаления: $e');
    }
  }

  Future<void> _deleteHardProductViaApi(int productId) async {
    final response = await dio.delete(
      '$apiSiteUrl/admin/products/$productId/hard',
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
        message: 'Ошибка удаления: ${response.statusCode}',
      );
    }
  }

  @override
  Future<void> deleteSoftProduct(int productId) async {
    try {
      await _deleteSoftProductViaApi(productId);
    } catch (e, st) {
      GetIt.instance<Talker>().handle(e, st);
      throw Exception('Ошибка мягкого удаления: $e');
    }
  }

  Future<void> _deleteSoftProductViaApi(int productId) async {
    final response = await dio.delete(
      '$apiSiteUrl/admin/products/$productId/soft',
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
        message: 'Ошибка удаления: ${response.statusCode}',
      );
    }
  }

  @override
  Future<void> postRestoreProduct(int productId) async {
    try {
      await _restoreProductViaApi(productId);
    } catch (e, st) {
      GetIt.instance<Talker>().handle(e, st);
      throw Exception('Ошибка восстановления продукта: $e');
    }
  }

  Future<void> _restoreProductViaApi(int productId) async {
    final response = await dio.post(
      '$apiSiteUrl/admin/products/$productId/restore',
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
        message: 'Ошибка восстановления: ${response.statusCode}',
      );
    }
  }

  @override
  Future<void> uploadProductImage(int productId, String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath,
            filename: filePath.split('/').last),
      });
      final response = await dio.post(
        '$apiSiteUrl/products/$productId/upload-image',
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          contentType: 'multipart/form-data',
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Ошибка загрузки изображения: ${response.statusCode}',
        );
      }
    } catch (e, st) {
      GetIt.instance<Talker>().handle(e, st);
      throw Exception('Ошибка загрузки изображения: $e');
    }
  }
}
