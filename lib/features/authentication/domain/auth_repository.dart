import 'user_model.dart';

abstract class AuthRepository {
  Future<UserModel> login(String email, String password, {bool rememberMe = true});
  Future<void> logout();
  Future<UserModel?> checkAuthStatus();
}
