import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:talker_flutter/talker_flutter.dart';
import '../product_variant.dart';

class ProductVariantRepository implements AbstractProductVariantRepository {
  ProductVariantRepository({
    required this.dio,
    required this.apiSiteUrl,
  });

  final Dio dio;
  final String apiSiteUrl;

  static String? get token =>
      GetIt.I<AbstractJWTTokensRepository>().getAccessToken();

  @override
  Future<List<VariantResponse>> getProductVariantList() async {
    try {
      return await _fetchProductVariantListFromApi();
    } catch (e, st) {
      GetIt.instance<Talker>().handle(e, st);
      throw Exception('Failed to get product variant list: $e');
    }
  }

  Future<List<VariantResponse>> _fetchProductVariantListFromApi() async {
    final response = await dio.get(
      '$apiSiteUrl/admin/variants',
      options: _defaultOptions,
    );

    _validateResponse(response, 'Failed to load variants');

    return (response.data as List)
        .map<VariantResponse>((item) => VariantResponse.fromJson(item))
        .toList();
  }

  @override
  Future<VariantResponse> getProductVariant(int productVariantId) async {
    try {
      return await _fetchProductVariantFromApi(productVariantId);
    } catch (e, st) {
      GetIt.instance<Talker>().handle(e, st);
      throw Exception('Failed to get product variant: $e');
    }
  }

  Future<VariantResponse> _fetchProductVariantFromApi(
      int productVariantId) async {
    final response = await dio.get(
      '$apiSiteUrl/admin/variants/$productVariantId',
      options: _defaultOptions,
    );

    _validateResponse(response, 'Failed to load variant $productVariantId');
    return VariantResponse.fromJson(response.data);
  }

  @override
  Future<VariantResponse> postCreateProductVariant(
      ProductVariantCreateDTO dto, int productId) async {
    try {
      return await _fetchCreatedProductVariantFromApi(dto, productId);
    } catch (e, st) {
      GetIt.instance<Talker>().handle(e, st);
      throw Exception('Failed to create product variant: $e');
    }
  }

  Future<VariantResponse> _fetchCreatedProductVariantFromApi(
      ProductVariantCreateDTO dto, int productId) async {
    final response = await dio.post(
      '$apiSiteUrl/admin/products/$productId/variants',
      data: dto.toJson(),
      options: _postOptions,
    );

    _validateResponse(response, 'Failed to create variant', successCode: 201);
    return VariantResponse.fromJson(response.data);
  }

  @override
  Future<VariantResponse> patchProductVariant(
      int productVariantId, ProductVariantPatchDTO dto) async {
    try {
      return await _fetchUpdatedProductVariantFromApi(productVariantId, dto);
    } catch (e, st) {
      GetIt.instance<Talker>().handle(e, st);
      throw Exception('Failed to update product variant: $e');
    }
  }

  Future<VariantResponse> _fetchUpdatedProductVariantFromApi(
      int productVariantId, ProductVariantPatchDTO dto) async {
    final response = await dio.patch(
      '$apiSiteUrl/admin/variants/$productVariantId',
      data: dto.toJson(),
      options: _postOptions,
    );

    _validateResponse(response, 'Failed to update variant $productVariantId');
    return VariantResponse.fromJson(response.data);
  }

  @override
  Future<void> deleteHardProductVariant(int productVariantId) async {
    try {
      await _deleteProductVariantViaApi(productVariantId, hardDelete: true);
    } catch (e, st) {
      GetIt.instance<Talker>().handle(e, st);
      throw Exception('Failed to hard delete variant: $e');
    }
  }

  @override
  Future<void> deleteSoftProductVariant(int productVariantId) async {
    try {
      await _deleteProductVariantViaApi(productVariantId, hardDelete: false);
    } catch (e, st) {
      GetIt.instance<Talker>().handle(e, st);
      throw Exception('Failed to soft delete variant: $e');
    }
  }

  Future<void> _deleteProductVariantViaApi(int productVariantId,
      {required bool hardDelete}) async {
    final endpoint = hardDelete ? 'hard' : 'soft';
    final response = await dio.delete(
      '$apiSiteUrl/admin/variants/$productVariantId/$endpoint',
      options: _defaultOptions,
    );

    _validateResponse(response, 'Failed to delete variant $productVariantId',
        successCode: 200);
  }

  @override
  Future<void> postRestoreProductVariant(int productVariantId) async {
    try {
      await _restoreProductVariantViaApi(productVariantId);
    } catch (e, st) {
      GetIt.instance<Talker>().handle(e, st);
      throw Exception('Failed to restore variant: $e');
    }
  }

  Future<void> _restoreProductVariantViaApi(int productVariantId) async {
    final response = await dio.post(
      '$apiSiteUrl/admin/variants/$productVariantId/restore',
      options: _defaultOptions,
    );

    _validateResponse(response, 'Failed to restore variant $productVariantId',
        successCode: 200);
  }

  Options get _defaultOptions => Options(
        headers: _authHeaders,
        receiveTimeout: const Duration(seconds: 5),
        sendTimeout: const Duration(seconds: 5),
      );

  Options get _postOptions => Options(
        headers: _authHeaders,
        contentType: Headers.jsonContentType,
        receiveTimeout: const Duration(seconds: 5),
        sendTimeout: const Duration(seconds: 5),
      );

  Map<String, String> get _authHeaders => {
        'Authorization': 'Bearer $token',
      };

  void _validateResponse(Response response, String errorMessage,
      {int successCode = 200}) {
    if (response.statusCode != successCode) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: '$errorMessage: ${response.statusCode}',
      );
    }
  }
}
