
abstract class AbstractJWTTokensRepository {
  Future<bool> getCheckJWTTokens();
  Future<bool> postRefreshAccessJWTToken();
  String? getAccessToken();
  Future<void> saveTokens(String accessToken, String refreshToken);
  Future<void> clearTokens();
}
