
import '../carts.dart';

abstract class AbstractCartRepository {

  Future<CartResponseDTO> getCart();

  Future<CartResponseDTO> addItemToCart(CartItemRequestDTO item);

  Future<CartResponseDTO> updateItemQuantity(int cartItemId, int newQuantity);

  Future<CartResponseDTO> deleteItemFromCart(int cartItemId);
}