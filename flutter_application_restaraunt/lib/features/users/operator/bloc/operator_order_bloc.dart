import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '/core/repositories/users/client/restaraunt/orders/dto/dto.dart';
import '/core/repositories/users/operator/orders/operator_orders_repository.dart';

abstract class OperatorOrderEvent {}

class StreamActiveOrders extends OperatorOrderEvent {}

class ModifyActiveOrderContent extends OperatorOrderEvent {
  ModifyActiveOrderContent({
    required this.orderId,
    required this.items,
    this.paymentMethod,
  });

  final int orderId;
  final List<Map<String, dynamic>> items;
  final String? paymentMethod;
}

class SaveOperatorOrderChanges extends OperatorOrderEvent {
  SaveOperatorOrderChanges({
    required this.orderId,
    required this.items,
    required this.status,
    this.paymentMethod,
    this.completer,
  });

  final int orderId;
  final List<Map<String, dynamic>> items;
  final String status;
  final String? paymentMethod;
  final Completer<void>? completer;
}

class OrdersUpdated extends OperatorOrderEvent {
  OrdersUpdated(this.orders);
  final List<OrderResponseDTO> orders;
}

abstract class OperatorOrderState {}

class OperatorOrdersLoading extends OperatorOrderState {}

class OperatorOrdersLoaded extends OperatorOrderState {
  OperatorOrdersLoaded(this.activeOrders);
  final List<OrderResponseDTO> activeOrders;
}

class OperatorOrderError extends OperatorOrderState {
  OperatorOrderError(this.error);
  final String error;
}

class OperatorOrderBloc extends Bloc<OperatorOrderEvent, OperatorOrderState> {
  OperatorOrderBloc(this._repository) : super(OperatorOrdersLoading()) {
    on<StreamActiveOrders>(_onStream);
    on<OrdersUpdated>(_onUpdated);
    on<ModifyActiveOrderContent>(_onModify);
    on<SaveOperatorOrderChanges>(_onSaveChanges);
  }

  final AbstractOperatorOrdersRepository _repository;

  bool _subscribed = false;

  Future<void> _onStream(
    StreamActiveOrders event,
    Emitter<OperatorOrderState> emit,
  ) async {
    try {
      if (_subscribed) {

        final orders = await _repository.getActiveOrders();
        emit(OperatorOrdersLoaded(orders));
        return;
      }
      emit(OperatorOrdersLoading());
      final initial = await _repository.getActiveOrders();
      emit(OperatorOrdersLoaded(initial));
      _subscribed = true;
      await emit.onEach<List<OrderResponseDTO>>(
        _repository.activeOrdersStream(),
        onData: (orders) => emit(OperatorOrdersLoaded(orders)),
      );
    } catch (e) {
      emit(OperatorOrderError(e.toString()));
    }
  }

  void _onUpdated(OrdersUpdated event, Emitter<OperatorOrderState> emit) {
    emit(OperatorOrdersLoaded(event.orders));
  }

  Future<void> _onModify(
    ModifyActiveOrderContent event,
    Emitter<OperatorOrderState> emit,
  ) async {
    try {
      await _repository.modifyActiveOrder(
        event.orderId,
        event.items,
        paymentMethod: event.paymentMethod,
      );
    } catch (e) {
      emit(OperatorOrderError(e.toString()));
    }
  }

  Future<void> _onSaveChanges(
    SaveOperatorOrderChanges event,
    Emitter<OperatorOrderState> emit,
  ) async {
    final completer = event.completer;
    try {
      await _repository.modifyActiveOrder(
        event.orderId,
        event.items,
        paymentMethod: event.paymentMethod,
      );
      await _repository.updateOrderStatus(
        event.orderId,
        OrderStatusUpdateRequestDTO(status: event.status),
      );

      try {
        final fresh = await _repository.getActiveOrders();
        emit(OperatorOrdersLoaded(fresh));
      } catch (_) {}
      if (completer != null && !completer.isCompleted) completer.complete();
    } catch (e) {
      if (completer != null && !completer.isCompleted) {
        completer.completeError(e);
      } else if (completer == null) {
        emit(OperatorOrderError(e.toString()));
      }
    }
  }
}
