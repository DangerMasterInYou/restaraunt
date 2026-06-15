import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '/core/repositories/services/jwt_tokens/jwt_tokens.dart';

class ReviewDTO {
  final int id;
  final int orderId;
  final int userId;
  final int rating;
  final String? text;
  final String? response;
  final String? respondedAt;
  final String? createdAt;
  final String? orderNumber;
  final String? customerName;
  final String? customerPhone;
  final String? customerEmail;

  const ReviewDTO({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.rating,
    this.text,
    this.response,
    this.respondedAt,
    this.createdAt,
    this.orderNumber,
    this.customerName,
    this.customerPhone,
    this.customerEmail,
  });

  factory ReviewDTO.fromJson(Map<String, dynamic> json) => ReviewDTO(
        id: (json['id'] as num).toInt(),
        orderId: (json['order_id'] as num).toInt(),
        userId: (json['user_id'] as num).toInt(),
        rating: (json['rating'] as num).toInt(),
        text: json['text'] as String?,
        response: json['response'] as String?,
        respondedAt: json['responded_at'] as String?,
        createdAt: json['created_at'] as String?,
        orderNumber: json['order_number'] as String?,
        customerName: json['customer_name'] as String?,
        customerPhone: json['customer_phone'] as String?,
        customerEmail: json['customer_email'] as String?,
      );
}

abstract class AbstractReviewsRepository {
  Future<ReviewDTO> createReview(int orderId, int rating, String? text);
  Future<List<ReviewDTO>> getMyReviews();
  Future<List<ReviewDTO>> getAllReviews();
  Future<ReviewDTO> respond(int reviewId, String response);
  Future<void> deleteReview(int reviewId);
}

class ReviewsRepository implements AbstractReviewsRepository {
  ReviewsRepository({required this.dio, required this.apiSiteUrl});

  final Dio dio;
  final String apiSiteUrl;

  static String? get _token =>
      GetIt.I<AbstractJWTTokensRepository>().getAccessToken();

  Options get _authOptions =>
      Options(headers: {'Authorization': 'Bearer $_token'});

  @override
  Future<ReviewDTO> createReview(int orderId, int rating, String? text) async {
    try {
      final response = await dio.post(
        '$apiSiteUrl/reviews',
        data: {'order_id': orderId, 'rating': rating, 'text': text},
        options: _authOptions,
      );
      return ReviewDTO.fromJson(response.data as Map<String, dynamic>);
    } catch (e, st) {
      GetIt.I<Talker>().handle(e, st);
      rethrow;
    }
  }

  @override
  Future<List<ReviewDTO>> getMyReviews() async {
    final response =
        await dio.get('$apiSiteUrl/reviews/my', options: _authOptions);
    return (response.data as List<dynamic>)
        .map((e) => ReviewDTO.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<ReviewDTO>> getAllReviews() async {
    final response =
        await dio.get('$apiSiteUrl/reviews/all', options: _authOptions);
    return (response.data as List<dynamic>)
        .map((e) => ReviewDTO.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ReviewDTO> respond(int reviewId, String response) async {
    final r = await dio.post(
      '$apiSiteUrl/admin/reviews/$reviewId/respond',
      data: {'response': response},
      options: _authOptions,
    );
    return ReviewDTO.fromJson(r.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteReview(int reviewId) async {
    await dio.delete('$apiSiteUrl/admin/reviews/$reviewId',
        options: _authOptions);
  }
}
