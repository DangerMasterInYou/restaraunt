import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:talker_flutter/talker_flutter.dart';
import '/core/repositories/users/client/restaraunt/carts/carts.dart';
import '/core/repositories/users/client/restaraunt/orders/orders.dart';

part 'cart_event.dart';
part 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc(this.cartRepository, this.ordersRepository) : super(CartInitial()) {
    on<LoadCart>(_onLoadCart);
    on<AddItemToCart>(_onAddItem);
    on<UpdateItemQuantity>(_onUpdateQuantity);
    on<RemoveItemFromCart>(_onRemoveItem);
    on<SetCheckoutDetails>(_onSetCheckoutDetails);
    on<PlaceOrder>(_onPlaceOrder);
  }

  final AbstractCartRepository cartRepository;
  final AbstractOrdersRepository ordersRepository;

  void _handleSuccess(CartResponseDTO response, Emitter<CartState> emit) {
    final previous = state is CartLoaded ? state as CartLoaded : null;
    emit(CartLoaded(
      cartResponse: response,
      customerName: previous?.customerName,
      customerPhone: previous?.customerPhone,
      comment: previous?.comment,
    ));
  }

  void _handleError(Object e, StackTrace st, Emitter<CartState> emit) {
    emit(CartLoadingFailure(exception: e));
    GetIt.I<Talker>().handle(e, st);
  }

  Future<void> _onLoadCart(LoadCart event, Emitter<CartState> emit) async {
    try {
      emit(CartLoading());
      final cartResponse = await cartRepository.getCart();
      final previous = state is CartLoaded ? state as CartLoaded : null;
      emit(CartLoaded(
        cartResponse: cartResponse,
        customerName: previous?.customerName,
        customerPhone: previous?.customerPhone,
        comment: previous?.comment,
      ));
    } catch (e, st) {
      _handleError(e, st, emit);
    }
  }

  Future<void> _onAddItem(AddItemToCart event, Emitter<CartState> emit) async {
    try {
      final newCartState = await cartRepository.addItemToCart(event.item);
      _handleSuccess(newCartState, emit);
    } catch (e, st) {
      _handleError(e, st, emit);
    }
  }

  Future<void> _onUpdateQuantity(
    UpdateItemQuantity event,
    Emitter<CartState> emit,
  ) async {
    try {
      final newCartState = await cartRepository.updateItemQuantity(
        event.cartItemId,
        event.newQuantity,
      );
      _handleSuccess(newCartState, emit);
    } catch (e, st) {
      _handleError(e, st, emit);
    }
  }

  Future<void> _onRemoveItem(
    RemoveItemFromCart event,
    Emitter<CartState> emit,
  ) async {
    try {
      final newCartState =
          await cartRepository.deleteItemFromCart(event.cartItemId);
      _handleSuccess(newCartState, emit);
    } catch (e, st) {
      _handleError(e, st, emit);
    }
  }

  void _onSetCheckoutDetails(
    SetCheckoutDetails event,
    Emitter<CartState> emit,
  ) {
    if (state is! CartLoaded) {
      return;
    }
    final loaded = state as CartLoaded;
    emit(loaded.copyWith(
      customerName: event.customerName,
      customerPhone: event.customerPhone,
      comment: event.comment,
    ));
  }

  Future<void> _onPlaceOrder(
    PlaceOrder event,
    Emitter<CartState> emit,
  ) async {
    if (state is! CartLoaded) {
      emit(CartLoadingFailure(
        exception: Exception('Корзина не загружена'),
      ));
      return;
    }

    final loaded = state as CartLoaded;

    if (loaded.cartResponse.items.isEmpty) {
      emit(CartLoadingFailure(
        exception: Exception('Нельзя оформить пустую корзину'),
      ));
      return;
    }

    final name = loaded.customerName?.trim();
    final phone = loaded.customerPhone?.trim();
    if (name == null ||
        name.isEmpty ||
        phone == null ||
        phone.isEmpty) {
      emit(CartLoadingFailure(
        exception: Exception('Заполните контактные данные'),
      ));
      return;
    }

    try {
      emit(CartPlacingOrder(cartResponse: loaded.cartResponse));

      final order = await ordersRepository.createOrder(
        OrderCreateRequestDTO(
          paymentMethod: event.paymentMethod,
          comment: (loaded.comment == null || loaded.comment!.trim().isEmpty)
              ? null
              : loaded.comment!.trim(),
          customerName: name,
          customerPhone: phone,
          returnUrl: event.returnUrl,
        ),
      );

      emit(CartOrderPlaced(order: order));
    } catch (e, st) {
      _handleError(e, st, emit);
    }
  }
}
