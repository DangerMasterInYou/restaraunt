part of 'orders_bloc.dart';

abstract class OrdersState extends Equatable {
  const OrdersState();

  @override
  List<Object?> get props => [];
}

class OrdersInitial extends OrdersState {
  const OrdersInitial();
}

class OrdersLoading extends OrdersState {
  const OrdersLoading();
}

class OrdersLoaded extends OrdersState {
  const OrdersLoaded({required this.ordersList, this.notice});

  final List<OrderResponseDTO> ordersList;

  final String? notice;

  @override
  List<Object?> get props => [ordersList, notice];
}

class OrdersLoadingFailure extends OrdersState {
  const OrdersLoadingFailure({this.exception});

  final Object? exception;

  @override
  List<Object?> get props => [exception];
}
