part of 'cart_bloc.dart';

abstract class CartState extends Equatable {
  const CartState();
}

class CartInitial extends CartState {
  @override
  List<Object?> get props => [];
}

class CartLoading extends CartState {
  @override
  List<Object?> get props => [];
}

class CartLoaded extends CartState {
  final CartResponseDTO cartResponse;
  final String? customerName;
  final String? customerPhone;
  final String? comment;

  const CartLoaded({
    required this.cartResponse,
    this.customerName,
    this.customerPhone,
    this.comment,
  });

  CartLoaded copyWith({
    CartResponseDTO? cartResponse,
    String? customerName,
    String? customerPhone,
    String? comment,
  }) {
    return CartLoaded(
      cartResponse: cartResponse ?? this.cartResponse,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      comment: comment ?? this.comment,
    );
  }

  @override
  List<Object?> get props =>
      [cartResponse, customerName, customerPhone, comment];
}

class CartPlacingOrder extends CartState {
  final CartResponseDTO cartResponse;

  const CartPlacingOrder({required this.cartResponse});

  @override
  List<Object?> get props => [cartResponse];
}

class CartOrderPlaced extends CartState {
  final OrderResponseDTO order;

  const CartOrderPlaced({required this.order});

  @override
  List<Object?> get props => [order];
}

class CartLoadingFailure extends CartState {
  final Object? exception;
  const CartLoadingFailure({this.exception});
  @override
  List<Object?> get props => [exception];
}
