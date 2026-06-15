// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderCreateRequestDTO _$OrderCreateRequestDTOFromJson(
        Map<String, dynamic> json) =>
    OrderCreateRequestDTO(
      paymentMethod: json['payment_method'] as String,
      comment: json['comment'] as String?,
      customerName: json['customer_name'] as String,
      customerPhone: json['customer_phone'] as String,
      returnUrl: json['return_url'] as String?,
    );

Map<String, dynamic> _$OrderCreateRequestDTOToJson(
        OrderCreateRequestDTO instance) =>
    <String, dynamic>{
      'payment_method': instance.paymentMethod,
      'comment': instance.comment,
      'customer_name': instance.customerName,
      'customer_phone': instance.customerPhone,
      'return_url': instance.returnUrl,
    };

OrderStatusUpdateRequestDTO _$OrderStatusUpdateRequestDTOFromJson(
        Map<String, dynamic> json) =>
    OrderStatusUpdateRequestDTO(
      status: json['status'] as String,
    );

Map<String, dynamic> _$OrderStatusUpdateRequestDTOToJson(
        OrderStatusUpdateRequestDTO instance) =>
    <String, dynamic>{
      'status': instance.status,
    };
