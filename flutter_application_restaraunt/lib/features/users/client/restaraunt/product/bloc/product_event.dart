part of 'product_bloc.dart';

abstract class ProductEvent extends Equatable {}

class LoadProduct extends ProductEvent {
  final int productId;
  LoadProduct({required this.productId});
  @override
  List<Object?> get props => [productId];
}
