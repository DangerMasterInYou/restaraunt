import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '/core/repositories/restaraunt/menu/menu.dart';

part 'product_event.dart';
part 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  ProductBloc() : super(ProductLoading()) {
    on<LoadProduct>(_onLoadProduct);
  }

  Future<void> _onLoadProduct(
      LoadProduct event, Emitter<ProductState> emit) async {
    emit(ProductLoading());
    try {
      final repo = GetIt.I<AbstractMenuRepository>();
      final Menu product = await repo.getMenu(event.productId);
      emit(ProductLoaded(product: product));
    } catch (e) {
      emit(ProductLoadingFailure(exception: e));
    }
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    super.onError(error, stackTrace);
    GetIt.I<Talker>().handle(error, stackTrace);
  }
}
