import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '/core/repositories/users/client/restaraunt/orders/orders.dart';

sealed class OrderDetailEvent extends Equatable {
  const OrderDetailEvent();
  @override
  List<Object?> get props => [];
}

class LoadOrderDetailByNumber extends OrderDetailEvent {
  const LoadOrderDetailByNumber(this.orderNumber);
  final String orderNumber;
  @override
  List<Object?> get props => [orderNumber];
}

class _OrderDetailRefetch extends OrderDetailEvent {
  const _OrderDetailRefetch();
}

sealed class OrderDetailState extends Equatable {
  const OrderDetailState();
  @override
  List<Object?> get props => [];
}

class OrderDetailLoading extends OrderDetailState {
  const OrderDetailLoading();
}

class OrderDetailLoaded extends OrderDetailState {
  const OrderDetailLoaded(this.order);
  final OrderResponseDTO order;
  @override
  List<Object?> get props => [order];
}

class OrderDetailFailure extends OrderDetailState {
  const OrderDetailFailure(this.exception);
  final Object exception;
  @override
  List<Object?> get props => [exception];
}

class OrderDetailBloc extends Bloc<OrderDetailEvent, OrderDetailState> {
  OrderDetailBloc(this._repo) : super(const OrderDetailLoading()) {
    on<LoadOrderDetailByNumber>(_onLoad);
    on<_OrderDetailRefetch>(_onRefetch);
  }

  final AbstractOrdersRepository _repo;
  String? _orderNumber;
  bool _wasActive = false;

  Future<void> _onLoad(
    LoadOrderDetailByNumber event,
    Emitter<OrderDetailState> emit,
  ) async {
    _orderNumber = event.orderNumber;
    try {
      emit(const OrderDetailLoading());
      final order = await _repo.getOrderByNumber(event.orderNumber);
      _wasActive = order.isActive;
      emit(OrderDetailLoaded(order));

      await emit.onEach<List<OrderResponseDTO>>(
        _repo.watchActiveOrders(),
        onData: (active) {
          final s = state;
          if (s is! OrderDetailLoaded) return;
          final cur = s.order;
          OrderResponseDTO? match;
          for (final a in active) {
            if (a.id == cur.id || a.orderNumber == cur.orderNumber) {
              match = a;
              break;
            }
          }
          if (match != null) {
            _wasActive = true;
            if (_differs(match, cur)) emit(OrderDetailLoaded(match));
          } else if (_wasActive) {

            _wasActive = false;
            add(const _OrderDetailRefetch());
          }
        },
      );
    } catch (e, st) {
      GetIt.I<Talker>().handle(e, st);
      emit(OrderDetailFailure(e));
    }
  }

  Future<void> _onRefetch(
    _OrderDetailRefetch event,
    Emitter<OrderDetailState> emit,
  ) async {
    final number = _orderNumber;
    if (number == null) return;
    try {
      final order = await _repo.getOrderByNumber(number);
      emit(OrderDetailLoaded(order));
    } catch (_) {

    }
  }

  bool _differs(OrderResponseDTO a, OrderResponseDTO b) {
    return a.status != b.status ||
        a.totalPrice != b.totalPrice ||
        a.payment?.status != b.payment?.status ||
        a.payment?.amount != b.payment?.amount ||
        a.statusHistory.length != b.statusHistory.length ||
        a.items.length != b.items.length;
  }
}
