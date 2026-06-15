import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '/core/repositories/restaraunt/menu/menu.dart';
import '/core/repositories/users/client/restaraunt/carts/carts.dart';

part 'menu_event.dart';
part 'menu_state.dart';

class MenuBloc extends Bloc<MenuEvent, MenuState> {
  MenuBloc(this.menuRepository, this.cartRepository) : super(MenuInitial()) {
    on<LoadMenu>(_load);
    on<AddItemCartMenu>(_addToCart);
  }

  final AbstractMenuRepository menuRepository;
  final AbstractCartRepository cartRepository;

  Future<void> _load(
    LoadMenu event,
    Emitter<MenuState> emit,
  ) async {
    try {
      emit(MenuLoading());

      List<Menu> menuList = [];
      try {
        menuList = await _withTimeout(
          menuRepository.getMenuList(),
          const Duration(
              seconds: 10),
          'Menu list fetch timeout',
        );
        if (menuList.isEmpty) {
          throw Exception('Menu not found (404)');
        }
      } catch (e, st) {
        GetIt.I<Talker>().handle(e, st);

        throw Exception('Failed to load menu items: $e');
      }

      emit(MenuLoaded(menuList: menuList, cartCount: await _cartCount()));
    } catch (e, st) {
      emit(MenuLoadingFailure(exception: e));
      GetIt.I<Talker>().handle(e, st);
    } finally {
      event.completer?.complete();
    }
  }

  Future<int> _cartCount() async {
    final token = GetIt.I<AbstractJWTTokensRepository>().getAccessToken();
    if (token == null || token.isEmpty) return 0;
    try {
      final cart = await cartRepository.getCart();
      return cart.items.fold<int>(0, (sum, i) => sum + i.quantity);
    } catch (_) {
      return 0;
    }
  }

  Future<T> _withTimeout<T>(
      Future<T> future, Duration timeout, String message) {
    return future.timeout(
      timeout,
      onTimeout: () => throw TimeoutException(message, timeout),
    );
  }

  Future<void> _addToCart(
    AddItemCartMenu event,
    Emitter<MenuState> emit,
  ) async {
    try {
      await cartRepository.addItemToCart(event.cartItemRequest);
      // Меню не перезагружаем (иначе MenuLoading рушит скролл и прыгает вверх) —
      // обновляем только счётчик корзины, сохраняя список и позицию прокрутки.
      final s = state;
      if (s is MenuLoaded) {
        emit(MenuLoaded(menuList: s.menuList, cartCount: await _cartCount()));
      } else {
        await _load(LoadMenu(), emit);
      }
    } catch (e, st) {
      GetIt.I<Talker>().handle(e, st);
      emit(MenuLoadingFailure(exception: e));
    }
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    super.onError(error, stackTrace);
    GetIt.I<Talker>().handle(error, stackTrace);
  }
}
