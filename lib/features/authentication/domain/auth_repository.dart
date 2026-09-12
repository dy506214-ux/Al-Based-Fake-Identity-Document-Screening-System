import 'user_model.dart';

abstract class AuthRepository {
  Future<UserModel> login(String email, String password, {bool rememberMe = true});
  Future<int> sendRegistrationOtp({required String name, required String mobile});
  Future<UserModel> verifyOtpAndRegister({required String name, required String mobile, required String otp});
  Future<void> logout();
  Future<UserModel?> checkAuthStatus();
}
