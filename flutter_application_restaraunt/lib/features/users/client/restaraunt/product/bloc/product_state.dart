part of 'product_bloc.dart';

abstract class ProductState extends Equatable {}

class ProductInitial extends ProductState {
  @override
  List<Object?> get props => [];
}

class ProductLoading extends ProductState {
  @override
  List<Object?> get props => [];
}

class ProductLoaded extends ProductState {
  ProductLoaded({required this.product});
  final Menu product;
  @override
  List<Object?> get props => [product];
}

class ProductLoadingFailure extends ProductState {
  ProductLoadingFailure({this.exception});
  final Object? exception;
  @override
  List<Object?> get props => [exception];
}
