import 'package:dio/dio.dart';

import '/core/hive/models/token/token.dart';
import 'abstract_jwt_tokens_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:talker_flutter/talker_flutter.dart';

class JWTTokensRepository extends AbstractJWTTokensRepository {
  JWTTokensRepository({
    required this.dio,
    required this.tokenBox,
    required this.apiSiteUrl,
  });

  final Dio dio;
  final Box<Token>tokenBox;
  final String apiSiteUrl;

  static const int tokenKey = 1;
  static String? get accessToken => GetIt.I<AbstractJWTTokensRepository>().getAccessToken();

  @override
  Future<bool> getCheckJWTTokens() async {
    bool currentTokens = false;
    try {
      if (tokenBox.isNotEmpty) {
        currentTokens = await _sendCheckJWTTokensRequest();
        if (currentTokens == false) {
          await tokenBox.clear();
        }
      }
    } catch (e, st) {
      GetIt.instance<Talker>().handle(e, st);
    }
    return currentTokens;
  }

  Future<bool> _sendCheckJWTTokensRequest() async {
    if (!tokenBox.containsKey(tokenKey)) {
      return false;
    }

    final token = tokenBox.get(tokenKey);
    if (token == null) {
      return false;
    }

    try {
      final response = await dio.post(
        '$apiSiteUrl/login/check',
        data: token.toJson(),
      );

      if (response.statusCode != 200) {
        return false;
      }

      return response.data['valid'] ?? false;
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 401) {
        return await _refreshAndRetry();
      }
      return false;
    }
  }

  Future<bool> _refreshAndRetry() async {
    final refreshSuccess = await postRefreshAccessJWTToken();
    if (refreshSuccess) {
      return await _sendCheckJWTTokensRequest();
    }
    return false;
  }

  @override
  Future<bool> postRefreshAccessJWTToken() async {
    if (!tokenBox.containsKey(tokenKey)) {
      return false;
    }

    final token = tokenBox.get(tokenKey);
    if (token == null) {
      return false;
    }

    try {
      final response = await dio.post(
        '$apiSiteUrl/login/refresh',
        data: token.toJson(),
      );

      if (response.statusCode != 200) {
        return false;
      }

      if (response.data is Map<String, dynamic> &&
          response.data['access'] != null &&
          response.data['refresh'] != null) {

        final newToken = Token(
          id: tokenKey,
          accessToken: response.data['access'],
          refreshToken: response.data['refresh'],
        );

        await tokenBox.put(tokenKey, newToken);
        return true;
      } else {
        return false;
      }
    } catch (e, st) {
      GetIt.instance<Talker>().handle(e, st);
      return false;
    }
  }

  @override
  String? getAccessToken() {
    if (!tokenBox.containsKey(tokenKey)) {
      return null;
    }

    final token = tokenBox.get(tokenKey);
    return token?.accessToken;
  }

  @override
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    final token = Token(
      id: tokenKey,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );

    await tokenBox.put(tokenKey, token);
  }

  @override
  Future<void> clearTokens() async {
    await tokenBox.clear();
  }
}