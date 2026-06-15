import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '/core/repositories/services/jwt_tokens/jwt_tokens.dart';
import '/core/repositories/users/client/restaraunt/orders/dto/dto.dart';

class AdminUserDTO {
  final int id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String role;
  final bool isActive;
  final String? createdAt;

  const AdminUserDTO({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.phone,
    required this.role,
    required this.isActive,
    this.createdAt,
  });

  String get fullName =>
      [firstName, lastName].where((e) => e != null && e.isNotEmpty).join(' ');

  factory AdminUserDTO.fromJson(Map<String, dynamic> json) {
    String role = (json['role'] ?? 'client').toString();

    if (role.contains('.')) role = role.split('.').last;
    return AdminUserDTO(
      id: (json['id'] as num).toInt(),
      email: json['email'] as String? ?? '',
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      phone: json['phone'] as String?,
      role: role,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] as String?,
    );
  }
}

abstract class AbstractAdminUsersRepository {
  Future<List<AdminUserDTO>> getUsers();
  Future<void> setRole(int userId, String role);
  Future<void> setActive(int userId, bool isActive);
  Future<void> createUser(Map<String, dynamic> data);
  Future<void> updateUser(int userId, Map<String, dynamic> data);
  Future<void> deleteUser(int userId, {bool hard = false});
}

abstract class AbstractAdminOrdersRepository {
  Future<List<OrderResponseDTO>> getAllOrders();
  Future<void> setStatus(int orderId, String status);
  Future<void> deleteOrder(int orderId);
}

class AdminUsersRepository implements AbstractAdminUsersRepository {
  AdminUsersRepository({required this.dio, required this.apiSiteUrl});
  final Dio dio;
  final String apiSiteUrl;

  static String? get _token =>
      GetIt.I<AbstractJWTTokensRepository>().getAccessToken();
  Options get _auth => Options(headers: {'Authorization': 'Bearer $_token'});

  @override
  Future<List<AdminUserDTO>> getUsers() async {
    try {
      final r = await dio.get('$apiSiteUrl/admin/users', options: _auth);
      return (r.data as List)
          .map((e) => AdminUserDTO.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      GetIt.I<Talker>().handle(e, st);
      rethrow;
    }
  }

  @override
  Future<void> setRole(int userId, String role) async {
    await dio.patch('$apiSiteUrl/admin/users/$userId/role',
        data: {'role': role}, options: _auth);
  }

  @override
  Future<void> setActive(int userId, bool isActive) async {
    await dio.patch('$apiSiteUrl/admin/users/$userId/active',
        data: {'is_active': isActive}, options: _auth);
  }

  @override
  Future<void> createUser(Map<String, dynamic> data) async {
    await dio.post('$apiSiteUrl/admin/users', data: data, options: _auth);
  }

  @override
  Future<void> updateUser(int userId, Map<String, dynamic> data) async {
    await dio.patch('$apiSiteUrl/admin/users/$userId',
        data: data, options: _auth);
  }

  @override
  Future<void> deleteUser(int userId, {bool hard = false}) async {
    await dio.delete('$apiSiteUrl/admin/users/$userId',
        queryParameters: {'hard': hard}, options: _auth);
  }
}

class AdminOrdersRepository implements AbstractAdminOrdersRepository {
  AdminOrdersRepository({required this.dio, required this.apiSiteUrl});
  final Dio dio;
  final String apiSiteUrl;

  static String? get _token =>
      GetIt.I<AbstractJWTTokensRepository>().getAccessToken();
  Options get _auth => Options(headers: {'Authorization': 'Bearer $_token'});

  @override
  Future<List<OrderResponseDTO>> getAllOrders() async {
    try {
      final r = await dio.get(
        '$apiSiteUrl/operator/orders',
        queryParameters: {'active_only': false},
        options: _auth,
      );
      return (r.data as List)
          .map((e) => OrderResponseDTO.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      GetIt.I<Talker>().handle(e, st);
      rethrow;
    }
  }

  @override
  Future<void> setStatus(int orderId, String status) async {
    await dio.patch('$apiSiteUrl/operator/orders/$orderId/status',
        data: {'status': status}, options: _auth);
  }

  @override
  Future<void> deleteOrder(int orderId) async {
    await dio.delete('$apiSiteUrl/admin/orders/$orderId', options: _auth);
  }
}
