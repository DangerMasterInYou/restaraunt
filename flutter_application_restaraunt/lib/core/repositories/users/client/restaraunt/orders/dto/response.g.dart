// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderProductDTO _$OrderProductDTOFromJson(Map<String, dynamic> json) =>
    OrderProductDTO(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
    );

Map<String, dynamic> _$OrderProductDTOToJson(OrderProductDTO instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
    };

OrderProductVariantDTO _$OrderProductVariantDTOFromJson(
        Map<String, dynamic> json) =>
    OrderProductVariantDTO(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      product:
          OrderProductDTO.fromJson(json['product'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$OrderProductVariantDTOToJson(
        OrderProductVariantDTO instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'product': instance.product,
    };

AppliedModifierDTO _$AppliedModifierDTOFromJson(Map<String, dynamic> json) =>
    AppliedModifierDTO(
      modifierId: (json['modifier_id'] as num).toInt(),
      name: json['name'] as String,
      quantity: (json['quantity'] as num).toInt(),
      priceDelta: (json['price_delta'] as num?)?.toInt(),
    );

Map<String, dynamic> _$AppliedModifierDTOToJson(AppliedModifierDTO instance) =>
    <String, dynamic>{
      'modifier_id': instance.modifierId,
      'name': instance.name,
      'quantity': instance.quantity,
      'price_delta': instance.priceDelta,
    };

OrderItemDTO _$OrderItemDTOFromJson(Map<String, dynamic> json) => OrderItemDTO(
      id: (json['id'] as num).toInt(),
      quantity: (json['quantity'] as num).toInt(),
      pricePerUnit: (json['price_per_unit'] as num?)?.toInt(),
      productVariant: OrderProductVariantDTO.fromJson(
          json['product_variant'] as Map<String, dynamic>),
      appliedModifiers: (json['applied_modifiers'] as List<dynamic>?)
              ?.map(
                  (e) => AppliedModifierDTO.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$OrderItemDTOToJson(OrderItemDTO instance) =>
    <String, dynamic>{
      'id': instance.id,
      'quantity': instance.quantity,
      'price_per_unit': instance.pricePerUnit,
      'product_variant': instance.productVariant,
      'applied_modifiers': instance.appliedModifiers,
    };

OrderPaymentDTO _$OrderPaymentDTOFromJson(Map<String, dynamic> json) =>
    OrderPaymentDTO(
      status: json['status'] as String,
      paymentSystem: json['payment_system'] as String?,
      amount: (json['amount'] as num?)?.toInt(),
    );

Map<String, dynamic> _$OrderPaymentDTOToJson(OrderPaymentDTO instance) =>
    <String, dynamic>{
      'status': instance.status,
      'payment_system': instance.paymentSystem,
      'amount': instance.amount,
    };

OrderStatusHistoryDTO _$OrderStatusHistoryDTOFromJson(
        Map<String, dynamic> json) =>
    OrderStatusHistoryDTO(
      status: json['status'] as String,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$OrderStatusHistoryDTOToJson(
        OrderStatusHistoryDTO instance) =>
    <String, dynamic>{
      'status': instance.status,
      'note': instance.note,
      'created_at': instance.createdAt.toIso8601String(),
    };

OrderResponseDTO _$OrderResponseDTOFromJson(Map<String, dynamic> json) =>
    OrderResponseDTO(
      id: (json['id'] as num).toInt(),
      orderNumber: json['order_number'] as String?,
      status: json['status'] as String,
      totalPrice: (json['total_price'] as num?)?.toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
      customerName: json['customer_name'] as String?,
      customerPhone: json['customer_phone'] as String?,
      comment: json['comment'] as String?,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => OrderItemDTO.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      payment: json['payment'] == null
          ? null
          : OrderPaymentDTO.fromJson(json['payment'] as Map<String, dynamic>),
      statusHistory: (json['status_history'] as List<dynamic>?)
              ?.map((e) =>
                  OrderStatusHistoryDTO.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      userId: (json['user_id'] as num?)?.toInt(),
      paymentMethod: json['payment_method'] as String?,
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      confirmationUrl: json['confirmation_url'] as String?,
    );

Map<String, dynamic> _$OrderResponseDTOToJson(OrderResponseDTO instance) =>
    <String, dynamic>{
      'id': instance.id,
      'order_number': instance.orderNumber,
      'status': instance.status,
      'total_price': instance.totalPrice,
      'created_at': instance.createdAt.toIso8601String(),
      'customer_name': instance.customerName,
      'customer_phone': instance.customerPhone,
      'comment': instance.comment,
      'items': instance.items,
      'payment': instance.payment,
      'status_history': instance.statusHistory,
      'user_id': instance.userId,
      'payment_method': instance.paymentMethod,
      'updated_at': instance.updatedAt?.toIso8601String(),
      'confirmation_url': instance.confirmationUrl,
    };
