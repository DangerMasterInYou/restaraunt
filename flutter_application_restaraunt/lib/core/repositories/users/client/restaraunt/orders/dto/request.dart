import 'package:json_annotation/json_annotation.dart';

part 'request.g.dart';

@JsonSerializable()
class OrderCreateRequestDTO {
  @JsonKey(name: 'payment_method')
  final String paymentMethod;

  final String? comment;

  @JsonKey(name: 'customer_name')
  final String customerName;

  @JsonKey(name: 'customer_phone')
  final String customerPhone;

  @JsonKey(name: 'return_url')
  final String? returnUrl;

  const OrderCreateRequestDTO({
    required this.paymentMethod,
    this.comment,
    required this.customerName,
    required this.customerPhone,
    this.returnUrl,
  });

  factory OrderCreateRequestDTO.fromJson(Map<String, dynamic> json) =>
      _$OrderCreateRequestDTOFromJson(json);

  Map<String, dynamic> toJson() => _$OrderCreateRequestDTOToJson(this);
}

@JsonSerializable()
class OrderStatusUpdateRequestDTO {
  final String status;

  const OrderStatusUpdateRequestDTO({required this.status});

  factory OrderStatusUpdateRequestDTO.fromJson(Map<String, dynamic> json) =>
      _$OrderStatusUpdateRequestDTOFromJson(json);

  Map<String, dynamic> toJson() => _$OrderStatusUpdateRequestDTOToJson(this);
}
