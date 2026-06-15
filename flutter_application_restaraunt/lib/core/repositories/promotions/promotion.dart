import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '/core/repositories/services/jwt_tokens/jwt_tokens.dart';

class PromotionDTO {
  final int? id;
  final String title;
  final String? description;
  final String? discountLabel;
  final String promoType;
  final int? discountValue;
  final String targetType;
  final int? targetId;
  final int? minOrderAmount;
  final String? startDate;
  final String? endDate;
  final String? startTime;
  final String? endTime;
  final String? daysOfWeek;
  final bool isActive;
  final bool isBirthday;

  const PromotionDTO({
    this.id,
    required this.title,
    this.description,
    this.discountLabel,
    this.promoType = 'percent',
    this.discountValue,
    this.targetType = 'all',
    this.targetId,
    this.minOrderAmount,
    this.startDate,
    this.endDate,
    this.startTime,
    this.endTime,
    this.daysOfWeek,
    this.isActive = true,
    this.isBirthday = false,
  });

  factory PromotionDTO.fromJson(Map<String, dynamic> json) => PromotionDTO(
        id: (json['id'] as num?)?.toInt(),
        title: json['title'] as String? ?? '',
        description: json['description'] as String?,
        discountLabel: json['discount_label'] as String?,
        promoType: json['promo_type'] as String? ?? 'percent',
        discountValue: (json['discount_value'] as num?)?.toInt(),
        targetType: json['target_type'] as String? ?? 'all',
        targetId: (json['target_id'] as num?)?.toInt(),
        minOrderAmount: (json['min_order_amount'] as num?)?.toInt(),
        startDate: json['start_date'] as String?,
        endDate: json['end_date'] as String?,
        startTime: json['start_time'] as String?,
        endTime: json['end_time'] as String?,
        daysOfWeek: json['days_of_week'] as String?,
        isActive: json['is_active'] as bool? ?? true,
        isBirthday: json['is_birthday'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'discount_label': discountLabel,
        'promo_type': promoType,
        'discount_value': discountValue,
        'target_type': targetType,
        'target_id': targetId,
        'min_order_amount': minOrderAmount,
        'start_date': startDate,
        'end_date': endDate,
        'start_time': startTime,
        'end_time': endTime,
        'days_of_week': daysOfWeek,
        'is_active': isActive,
        'is_birthday': isBirthday,
      };
}

abstract class AbstractPromotionsRepository {
  Future<List<PromotionDTO>> getActive();
  Future<List<PromotionDTO>> getAll();
  Future<void> create(PromotionDTO promo);
  Future<void> update(int id, PromotionDTO promo);
  Future<void> delete(int id);
}

class PromotionsRepository implements AbstractPromotionsRepository {
  PromotionsRepository({required this.dio, required this.apiSiteUrl});

  final Dio dio;
  final String apiSiteUrl;

  static String? get _token =>
      GetIt.I<AbstractJWTTokensRepository>().getAccessToken();

  Options get _authOptions =>
      Options(headers: {'Authorization': 'Bearer $_token'});

  @override
  Future<List<PromotionDTO>> getActive() async {
    try {
      final response = await dio.get('$apiSiteUrl/promotions/active');
      final data = response.data as List<dynamic>;
      return data
          .map((e) => PromotionDTO.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      GetIt.I<Talker>().handle(e, st);
      rethrow;
    }
  }

  @override
  Future<List<PromotionDTO>> getAll() async {
    final response =
        await dio.get('$apiSiteUrl/admin/promotions', options: _authOptions);
    final data = response.data as List<dynamic>;
    return data
        .map((e) => PromotionDTO.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> create(PromotionDTO promo) async {
    await dio.post('$apiSiteUrl/admin/promotions',
        data: promo.toJson(), options: _authOptions);
  }

  @override
  Future<void> update(int id, PromotionDTO promo) async {
    await dio.patch('$apiSiteUrl/admin/promotions/$id',
        data: promo.toJson(), options: _authOptions);
  }

  @override
  Future<void> delete(int id) async {
    await dio.delete('$apiSiteUrl/admin/promotions/$id', options: _authOptions);
  }
}
