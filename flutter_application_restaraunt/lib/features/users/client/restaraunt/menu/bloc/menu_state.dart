part of 'menu_bloc.dart';

abstract class MenuState extends Equatable {}

class MenuInitial extends MenuState {
  @override
  List<Object?> get props => [];
}

class MenuLoading extends MenuState {
  @override
  List<Object?> get props => [];
}

class MenuLoaded extends MenuState {
  MenuLoaded({
    required this.menuList,
    this.cartCount = 0,
  });

  final List<Menu> menuList;

  final int cartCount;

  @override
  List<Object?> get props => [menuList, cartCount];
}

class MenuLoadingFailure extends MenuState {
  MenuLoadingFailure({
    this.exception,
  });

  final Object? exception;

  @override
  List<Object?> get props => [exception];
}
