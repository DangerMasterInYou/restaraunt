import 'package:json_annotation/json_annotation.dart';

part 'response.g.dart';

@JsonSerializable()
class OrderProductDTO {
  final int id;
  final String name;

  const OrderProductDTO({required this.id, required this.name});

  factory OrderProductDTO.fromJson(Map<String, dynamic> json) =>
      _$OrderProductDTOFromJson(json);

  Map<String, dynamic> toJson() => _$OrderProductDTOToJson(this);
}

@JsonSerializable()
class OrderProductVariantDTO {
  final int id;
  final String name;
  final OrderProductDTO product;

  const OrderProductVariantDTO({
    required this.id,
    required this.name,
    required this.product,
  });

  factory OrderProductVariantDTO.fromJson(Map<String, dynamic> json) =>
      _$OrderProductVariantDTOFromJson(json);

  Map<String, dynamic> toJson() => _$OrderProductVariantDTOToJson(this);
}

@JsonSerializable()
class AppliedModifierDTO {
  @JsonKey(name: 'modifier_id')
  final int modifierId;
  final String name;
  final int quantity;

  @JsonKey(name: 'price_delta')
  final int? priceDelta;

  const AppliedModifierDTO({
    required this.modifierId,
    required this.name,
    required this.quantity,
    this.priceDelta,
  });

  factory AppliedModifierDTO.fromJson(Map<String, dynamic> json) =>
      _$AppliedModifierDTOFromJson(json);

  Map<String, dynamic> toJson() => _$AppliedModifierDTOToJson(this);
}

@JsonSerializable()
class OrderItemDTO {
  final int id;
  final int quantity;

  @JsonKey(name: 'price_per_unit')
  final int? pricePerUnit;

  @JsonKey(name: 'product_variant')
  final OrderProductVariantDTO productVariant;

  @JsonKey(name: 'applied_modifiers', defaultValue: <AppliedModifierDTO>[])
  final List<AppliedModifierDTO> appliedModifiers;

  const OrderItemDTO({
    required this.id,
    required this.quantity,
    this.pricePerUnit,
    required this.productVariant,
    this.appliedModifiers = const [],
  });

  factory OrderItemDTO.fromJson(Map<String, dynamic> json) =>
      _$OrderItemDTOFromJson(json);

  Map<String, dynamic> toJson() => _$OrderItemDTOToJson(this);
}

@JsonSerializable()
class OrderPaymentDTO {
  final String status;

  @JsonKey(name: 'payment_system')
  final String? paymentSystem;

  final int? amount;

  const OrderPaymentDTO({
    required this.status,
    this.paymentSystem,
    this.amount,
  });

  factory OrderPaymentDTO.fromJson(Map<String, dynamic> json) =>
      _$OrderPaymentDTOFromJson(json);

  Map<String, dynamic> toJson() => _$OrderPaymentDTOToJson(this);
}

@JsonSerializable()
class OrderStatusHistoryDTO {
  final String status;

  final String? note;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const OrderStatusHistoryDTO({
    required this.status,
    this.note,
    required this.createdAt,
  });

  factory OrderStatusHistoryDTO.fromJson(Map<String, dynamic> json) =>
      _$OrderStatusHistoryDTOFromJson(json);

  Map<String, dynamic> toJson() => _$OrderStatusHistoryDTOToJson(this);
}

@JsonSerializable()
class OrderResponseDTO {
  final int id;

  @JsonKey(name: 'order_number')
  final String? orderNumber;

  final String status;

  @JsonKey(name: 'total_price')
  final int? totalPrice;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'customer_name')
  final String? customerName;

  @JsonKey(name: 'customer_phone')
  final String? customerPhone;

  final String? comment;

  @JsonKey(defaultValue: <OrderItemDTO>[])
  final List<OrderItemDTO> items;

  final OrderPaymentDTO? payment;

  @JsonKey(name: 'status_history', defaultValue: <OrderStatusHistoryDTO>[])
  final List<OrderStatusHistoryDTO> statusHistory;

  @JsonKey(name: 'user_id')
  final int? userId;

  @JsonKey(name: 'payment_method')
  final String? paymentMethod;

  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  @JsonKey(name: 'confirmation_url')
  final String? confirmationUrl;

  const OrderResponseDTO({
    required this.id,
    this.orderNumber,
    required this.status,
    this.totalPrice,
    required this.createdAt,
    this.customerName,
    this.customerPhone,
    this.comment,
    this.items = const [],
    this.payment,
    this.statusHistory = const [],
    this.userId,
    this.paymentMethod,
    this.updatedAt,
    this.confirmationUrl,
  });

  factory OrderResponseDTO.fromJson(Map<String, dynamic> json) =>
      _$OrderResponseDTOFromJson(json);

  Map<String, dynamic> toJson() => _$OrderResponseDTOToJson(this);
}

extension OrderResponseDTOX on OrderResponseDTO {
  String get displayNumber => orderNumber ?? '#$id';

  bool get isArchived {
    final normalized = status.toLowerCase();
    return normalized.contains('выдан') ||
        normalized.contains('отклон') ||
        normalized.contains('отмен') ||
        normalized.contains('заверш');
  }

  bool get isActive => !isArchived;

  String _paymentName(String? code) {
    switch (code) {
      case 'cash':
        return 'Наличные';
      case 'online':
      case 'yookassa':
      case 'sbp':
        return 'Онлайн';
      case 'card':
      case 'online_card':
        return 'Карта';
      default:
        return code ?? '—';
    }
  }

  String get paymentLabel {
    if (payment != null) {
      return _paymentName(payment!.paymentSystem);
    }
    if (paymentMethod == 'cash') return 'Наличные';
    if (paymentMethod == 'online') return 'Онлайн';
    return paymentMethod ?? '—';
  }
}
