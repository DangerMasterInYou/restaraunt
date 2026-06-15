import 'dart:async';

import 'package:dio/dio.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:get_it/get_it.dart';

import '/core/repositories/users/client/restaraunt/orders/orders.dart';
import '/core/repositories/services/jwt_tokens/jwt_tokens.dart';
import 'notification_service.dart';

class OrderNotificationsService {
  OrderNotificationsService(this._orders, this._tokens);

  final AbstractOrdersRepository _orders;
  final AbstractJWTTokensRepository _tokens;

  StreamSubscription<List<OrderResponseDTO>>? _sub;
  Timer? _refreshTimer;
  final Map<int, String> _known = {};
  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    if (_tokens.getAccessToken() == null) return;
    final ok = await _refreshKnown(seed: true);
    if (!ok) return;
    _started = true;
    _sub = _orders.watchActiveOrders().listen(
          _onActive,
          onError: (Object e, StackTrace st) => GetIt.I<Talker>().handle(e, st),
        );
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _refreshKnown(),
    );
  }

  Future<bool> _refreshKnown({bool seed = false}) async {
    try {
      final list = await _orders.getOrdersList(suppressAuthRedirect: true);
      for (final o in list) {
        if (seed) {
          _known[o.id] = o.status;
        } else {
          _known.putIfAbsent(o.id, () => o.status);
        }
      }
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        stop();
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  void _onActive(List<OrderResponseDTO> active) {
    for (final o in active) {
      final prev = _known[o.id];
      if (prev == null) continue;
      if (prev != o.status) {
        _known[o.id] = o.status;
        NotificationService.instance.show(
          'Заказ ${o.displayNumber}',
          'Статус: ${o.status}',
          id: o.id,
        );
      }
    }
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _known.clear();
    _started = false;
  }
}
