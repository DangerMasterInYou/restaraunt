import '../dto/dto.dart';

abstract class AbstractOrdersRepository {
  Future<List<OrderResponseDTO>> getOrdersList({bool suppressAuthRedirect});

  Future<OrderResponseDTO> getOrder(int orderId);

  Future<OrderResponseDTO> getOrderByNumber(String orderNumber);

  Future<OrderResponseDTO> createOrder(OrderCreateRequestDTO request);

  Future<String> initPayment(int orderId, {String? returnUrl});

  Future<OrderResponseDTO> confirmPayment(int orderId);

  Stream<List<OrderResponseDTO>> watchActiveOrders();
}
