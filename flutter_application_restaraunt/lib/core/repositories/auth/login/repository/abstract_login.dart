import '../login.dart';

abstract class AbstractLoginRepository {
  Future<bool> sendVerificationCode(String email);
  Future<Token?> verifyCode(String email, String code);
  void resetAttempts();

  String? get lastRole;
}
