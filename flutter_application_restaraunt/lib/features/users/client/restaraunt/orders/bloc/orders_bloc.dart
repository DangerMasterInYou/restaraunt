import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '/core/repositories/users/client/restaraunt/orders/orders.dart';

part 'orders_event.dart';
part 'orders_state.dart';

class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  OrdersBloc(this.ordersRepository) : super(const OrdersInitial()) {
    on<LoadOrders>(_onLoadOrders);
    on<RefreshOrders>(_onRefreshOrders);
  }

  final AbstractOrdersRepository ordersRepository;
  bool _watching = false;

  Future<void> _onRefreshOrders(
    RefreshOrders event,
    Emitter<OrdersState> emit,
  ) async {
    try {
      final orders = await ordersRepository.getOrdersList();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      emit(OrdersLoaded(ordersList: orders));
    } catch (_) {

    }
  }

  Future<void> _onLoadOrders(
    LoadOrders event,
    Emitter<OrdersState> emit,
  ) async {
    try {
      emit(const OrdersLoading());
      final orders = await ordersRepository.getOrdersList();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      emit(OrdersLoaded(ordersList: orders));

      if (!_watching) {
        _watching = true;
        await emit.onEach<List<OrderResponseDTO>>(
          ordersRepository.watchActiveOrders(),
          onData: (active) {
            final s = state;
            final current =
                s is OrdersLoaded ? s.ordersList : orders;
            final byId = {for (final a in active) a.id: a};
            String? notice;
            final merged = current.map((o) {
              final upd = byId[o.id];
              if (upd != null && upd.status != o.status) {
                notice = 'Заказ ${o.displayNumber}: ${upd.status}';
                return upd;
              }
              return o;
            }).toList();
            emit(OrdersLoaded(ordersList: merged, notice: notice));
          },
        );
      }
    } catch (e, st) {
      GetIt.I<Talker>().handle(e, st);
      emit(OrdersLoadingFailure(exception: e));
    }
  }

}
