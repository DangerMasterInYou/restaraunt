import 'package:dio/dio.dart';

import '../login.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:talker_flutter/talker_flutter.dart';

import 'package:hive/hive.dart';

class AttemptsExceededException implements Exception {
  final String message;
  final int attemptsLeft;
  AttemptsExceededException(this.message, {this.attemptsLeft = 0});

  @override
  String toString() => message;
}

class LoginRepository implements AbstractLoginRepository {
  int _attempts = 0;
  DateTime? _blockUntil;

  String? _lastRole;
  @override
  String? get lastRole => _lastRole;

  static const int maxAttempts = 5;
  static const Duration blockDuration = Duration(minutes: 1);

  @override
  void resetAttempts() {
    _attempts = 0;
    _blockUntil = null;
  }

  void _decrementAttempts() {
    _attempts++;
    if (_attempts >= maxAttempts) {
      _blockUntil = DateTime.now().add(blockDuration);
      _attempts = 0;
    }
  }

  bool get isBlocked {
    if (_blockUntil == null) return false;
    if (DateTime.now().isAfter(_blockUntil!)) {
      resetAttempts();
      return false;
    }
    return true;
  }

  LoginRepository({
    required this.dio,
    required this.tokenBox,
    required this.apiSiteUrl,
  });

  final Dio dio;
  final Box<Token> tokenBox;
  final String apiSiteUrl;

  final tokenkey = 1;

  @override
  Future<bool> sendVerificationCode(String email) async {
    try {
      final sendCodeDTO = {'email': email};
      final response =
          await dio.post('$apiSiteUrl/auth/send-code', data: sendCodeDTO);

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data['success'] == true;
      } else {
        throw Exception(
            'Ошибка отправки кода: ${response.statusCode}, ${response.data}');
      }
    } on DioException catch (e) {
      GetIt.instance<Talker>()
          .handle(e, e.stackTrace, 'DioException on sendVerificationCode');
      throw Exception('Ошибка соединения: ${e.message}');
    } catch (e, st) {
      _decrementAttempts();
      GetIt.instance<Talker>()
          .handle(e, st, 'Exception on sendVerificationCode');
      throw AttemptsExceededException('Осталось попыток: ${5 - _attempts}');
    }
  }

  @override
  Future<Token?> verifyCode(String email, String code) async {
    if (isBlocked) {
      throw AttemptsExceededException(
          'Слишком много попыток. Пожалуйста, подождите.',
          attemptsLeft: 0);
    }
    try {
      final verifyCodeDTO = {'email': email, 'code': code};
      final response =
          await dio.post('$apiSiteUrl/auth/verify-code', data: verifyCodeDTO);

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true &&
            data['token'] != null &&
            data['user'] != null) {
          final int tokenId = 1;

          final tokenData = {
            'id': tokenId,
            'access': data['token'],
            'refresh': data['refresh_token'] ?? ''
          };
          final token = Token.fromJson(tokenData);
          await tokenBox.put(1, token);

          _lastRole = (data['user'] as Map<String, dynamic>?)?['role'] as String?;
          resetAttempts();
          return token;
        } else {
          throw Exception(
              'Ошибка верификации кода: неверный ответ сервера ${response.data}');
        }
      }
      return null;
    } on DioException catch (e, st) {
      GetIt.instance<Talker>().handle(e, st, 'DioException on verifyCode');

      final data = e.response?.data;
      final detail = (data is Map) ? data['detail'] : null;
      if (detail is Map) {
        final blocked = (detail['blocked_seconds'] as num?)?.toInt() ?? 0;
        final left = (detail['attempts_left'] as num?)?.toInt();
        if (blocked > 0) {
          _blockUntil = DateTime.now().add(Duration(seconds: blocked));
          throw AttemptsExceededException(
              'Слишком много попыток. Подождите $blocked с.',
              attemptsLeft: 0);
        }
        if (left != null) {
          if (left <= 0) {
            throw AttemptsExceededException(
                'Слишком много попыток. Пожалуйста, подождите.',
                attemptsLeft: 0);
          }
          throw AttemptsExceededException(
              'Неверный код. Осталось попыток: $left',
              attemptsLeft: left);
        }
      }
      throw AttemptsExceededException('Ошибка проверки кода',
          attemptsLeft: maxAttempts - 1);
    } catch (e, st) {
      GetIt.instance<Talker>().handle(e, st, 'Exception on verifyCode');
      throw Exception('Неизвестная ошибка: $e');
    }
  }
}
