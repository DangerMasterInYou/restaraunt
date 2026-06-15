import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '/core/repositories/services/jwt_tokens/jwt_tokens.dart';
import '/core/services/ws_url.dart';
import '../dto/dto.dart';
import 'abstract_orders.dart';

class OrdersRepository implements AbstractOrdersRepository {
  OrdersRepository({
    required this.dio,
    required this.apiSiteUrl,
    this.ordersCacheBox,
  });

  final Dio dio;
  final String apiSiteUrl;

  WebSocketChannel? _wsChannel;
  final _activeOrdersController =
      StreamController<List<OrderResponseDTO>>.broadcast();

  @override
  Stream<List<OrderResponseDTO>> watchActiveOrders() {
    if (_wsChannel == null) {
      _wsChannel = WebSocketChannel.connect(
        Uri.parse(resolveWsUrl(apiSiteUrl, '/orders/active/ws')),
      );
      _wsChannel!.stream.listen(
        (message) {
          try {
            final decoded = jsonDecode(message as String) as List<dynamic>;
            _activeOrdersController.add(decoded
                .map((e) =>
                    OrderResponseDTO.fromJson(e as Map<String, dynamic>))
                .toList());
          } catch (e, st) {
            GetIt.I<Talker>().handle(e, st);
          }
        },
        onError: (Object e, StackTrace st) {
          GetIt.I<Talker>().handle(e, st);
          _wsChannel = null;
        },
        onDone: () => _wsChannel = null,
      );
    }
    return _activeOrdersController.stream;
  }

  final Box<String>? ordersCacheBox;

  void _cacheOrders(List<OrderResponseDTO> orders) {
    final box = ordersCacheBox;
    if (box == null) return;
    try {
      box.clear();
      box.putAll({
        for (final o in orders) o.id.toString(): jsonEncode(o.toJson()),
      });
    } catch (e, st) {
      GetIt.I<Talker>().handle(e, st);
    }
  }

  List<OrderResponseDTO> _readCachedOrders() {
    final box = ordersCacheBox;
    if (box == null) return const [];
    return box.values
        .map((raw) => OrderResponseDTO.fromJson(
            jsonDecode(raw) as Map<String, dynamic>))
        .toList();
  }

  static String? get _token =>
      GetIt.I<AbstractJWTTokensRepository>().getAccessToken();

  Options get _authOptions =>
      Options(headers: {'Authorization': 'Bearer $_token'});

  @override
  Future<List<OrderResponseDTO>> getOrdersList({
    bool suppressAuthRedirect = false,
  }) async {
    try {
      final response = await dio.get(
        '$apiSiteUrl/orders/my',
        options: Options(
          headers: {'Authorization': 'Bearer $_token'},
          extra: suppressAuthRedirect ? const {'skipAuthRedirect': true} : null,
        ),
      );
      final data = response.data;
      if (data is! List) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Неожиданный формат списка заказов',
        );
      }
      final orders = data
          .map(
              (item) => OrderResponseDTO.fromJson(item as Map<String, dynamic>))
          .toList();
      _cacheOrders(orders);
      return orders;
    } on DioException catch (e, st) {
      GetIt.I<Talker>().handle(e, st);

      final cached = _readCachedOrders();
      if (cached.isNotEmpty) return cached;
      rethrow;
    }
  }

  @override
  Future<OrderResponseDTO> getOrder(int orderId) async {
    try {
      final response = await dio.get(
        '$apiSiteUrl/orders/$orderId',
        options: _authOptions,
      );
      return OrderResponseDTO.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e, st) {
      GetIt.I<Talker>().handle(e, st);
      rethrow;
    }
  }

  @override
  Future<OrderResponseDTO> getOrderByNumber(String orderNumber) async {
    try {
      final response = await dio.get(
        '$apiSiteUrl/orders/by-number/$orderNumber',
        options: _authOptions,
      );
      return OrderResponseDTO.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e, st) {
      GetIt.I<Talker>().handle(e, st);
      rethrow;
    }
  }

  @override
  Future<OrderResponseDTO> createOrder(OrderCreateRequestDTO request) async {
    try {
      final response = await dio.post(
        '$apiSiteUrl/orders/create',
        data: request.toJson(),
        options: _authOptions,
      );
      return OrderResponseDTO.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e, st) {
      GetIt.I<Talker>().handle(e, st);
      rethrow;
    }
  }

  @override
  Future<String> initPayment(int orderId, {String? returnUrl}) async {
    try {
      final response = await dio.post(
        '$apiSiteUrl/payments/$orderId/init',
        data: {if (returnUrl != null) 'return_url': returnUrl},
        options: _authOptions,
      );
      final data = response.data as Map<String, dynamic>;
      return data['confirmation_url'] as String;
    } on DioException catch (e, st) {
      GetIt.I<Talker>().handle(e, st);
      rethrow;
    }
  }

  @override
  Future<OrderResponseDTO> confirmPayment(int orderId) async {
    try {
      final response = await dio.post(
        '$apiSiteUrl/payments/$orderId/confirm',
        options: _authOptions,
      );
      return OrderResponseDTO.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e, st) {
      GetIt.I<Talker>().handle(e, st);
      rethrow;
    }
  }

}
