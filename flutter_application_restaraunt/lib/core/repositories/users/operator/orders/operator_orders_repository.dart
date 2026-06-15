import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '/core/repositories/services/jwt_tokens/jwt_tokens.dart';
import '/core/repositories/users/client/restaraunt/orders/dto/dto.dart';
import '/core/services/ws_url.dart';

abstract class AbstractOperatorOrdersRepository {
  Future<List<OrderResponseDTO>> getActiveOrders();

  Future<OrderResponseDTO> updateOrderStatus(
    int orderId,
    OrderStatusUpdateRequestDTO request,
  );

  Future<OrderResponseDTO> modifyActiveOrder(
    int orderId,
    List<Map<String, dynamic>> items, {
    String? paymentMethod,
  });

  Future<OrderResponseDTO> createOrder(Map<String, dynamic> payload);

  Future<List<OrderResponseDTO>> getArchivedOrders();

  Future<OrderResponseDTO> refundOrder(int orderId, {int? amount});

  Future<OrderResponseDTO> setBirthdayDiscount(int orderId, bool enabled);

  Future<OrderResponseDTO> markCashPaid(int orderId);

  Stream<List<OrderResponseDTO>> activeOrdersStream();
}

class OperatorOrdersRepository implements AbstractOperatorOrdersRepository {
  OperatorOrdersRepository({required this.dio, required this.apiSiteUrl});

  final Dio dio;
  final String apiSiteUrl;

  WebSocketChannel? _channel;
  final _ordersController =
      StreamController<List<OrderResponseDTO>>.broadcast();

  static String? get _token =>
      GetIt.I<AbstractJWTTokensRepository>().getAccessToken();

  Options get _authOptions => Options(
        headers: {'Authorization': 'Bearer $_token'},
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
      );

  @override
  Future<List<OrderResponseDTO>> getActiveOrders() async {
    final response = await dio.get(
      '$apiSiteUrl/operator/orders',
      options: _authOptions,
    );
    final data = response.data as List<dynamic>;
    return data
        .map((e) => OrderResponseDTO.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<OrderResponseDTO> createOrder(Map<String, dynamic> payload) async {
    final response = await dio.post(
      '$apiSiteUrl/operator/orders/create',
      data: payload,
      options: _authOptions,
    );
    return OrderResponseDTO.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<OrderResponseDTO> refundOrder(int orderId, {int? amount}) async {
    final response = await dio.post(
      '$apiSiteUrl/payments/$orderId/refund',
      data: {if (amount != null) 'amount': amount},
      options: _authOptions,
    );
    return OrderResponseDTO.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<OrderResponseDTO> setBirthdayDiscount(int orderId, bool enabled) async {
    final response = await dio.patch(
      '$apiSiteUrl/operator/orders/$orderId/birthday-discount',
      queryParameters: {'enabled': enabled},
      options: _authOptions,
    );
    return OrderResponseDTO.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<OrderResponseDTO> markCashPaid(int orderId) async {
    final response = await dio.post(
      '$apiSiteUrl/payments/$orderId/pay',
      options: _authOptions,
    );
    return OrderResponseDTO.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<OrderResponseDTO>> getArchivedOrders() async {
    final response = await dio.get(
      '$apiSiteUrl/operator/orders',
      queryParameters: {'active_only': false},
      options: _authOptions,
    );
    final data = response.data as List<dynamic>;
    final all = data
        .map((e) => OrderResponseDTO.fromJson(e as Map<String, dynamic>))
        .toList();

    return all.where((o) => o.isArchived).toList();
  }

  @override
  Future<OrderResponseDTO> updateOrderStatus(
    int orderId,
    OrderStatusUpdateRequestDTO request,
  ) async {
    final response = await dio.patch(
      '$apiSiteUrl/operator/orders/$orderId/status',
      data: request.toJson(),
      options: _authOptions,
    );
    return OrderResponseDTO.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<OrderResponseDTO> modifyActiveOrder(
    int orderId,
    List<Map<String, dynamic>> items, {
    String? paymentMethod,
  }) async {
    final response = await dio.put(
      '$apiSiteUrl/operator/orders/$orderId/items',
      data: {
        'items': items,
        if (paymentMethod != null) 'payment_method': paymentMethod,
      },
      options: _authOptions,
    );
    return OrderResponseDTO.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Stream<List<OrderResponseDTO>> activeOrdersStream() {
    _connectWebSocket();
    return _ordersController.stream;
  }

  void _connectWebSocket() {
    if (_channel != null) return;
    final uri = Uri.parse(resolveWsUrl(apiSiteUrl, '/orders/active/ws'));
    _channel = WebSocketChannel.connect(uri);
    _channel!.stream.listen(
      (message) {
        try {
          final decoded = jsonDecode(message as String) as List<dynamic>;
          final orders = decoded
              .map((e) => OrderResponseDTO.fromJson(e as Map<String, dynamic>))
              .toList();
          _ordersController.add(orders);
        } catch (e, st) {
          GetIt.I<Talker>().handle(e, st);
        }
      },
      onError: (Object e, StackTrace st) {
        GetIt.I<Talker>().handle(e, st);
        _channel = null;
      },
      onDone: () {
        _channel = null;
      },
    );
  }

  void dispose() {
    _channel?.sink.close();
    _ordersController.close();
  }
}
