part of 'menu_bloc.dart';

abstract class MenuEvent extends Equatable {}

class LoadMenu extends MenuEvent {
  LoadMenu({
    this.completer,
  });

  final Completer? completer;

  @override
  List<Object?> get props => [completer];
}

class AddItemCartMenu extends MenuEvent {
  AddItemCartMenu({
    required this.cartItemRequest,
  });

  final CartItemRequestDTO cartItemRequest;

  @override
  List<Object?> get props => [cartItemRequest];
}
