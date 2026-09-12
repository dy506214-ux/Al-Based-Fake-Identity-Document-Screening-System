import 'user_model.dart';

class GeneratedCredentials {
  final String loginId;
  final String password;
  final String name;
  final String mobile;

  const GeneratedCredentials({
    required this.loginId,
    required this.password,
    required this.name,
    required this.mobile,
  });

  factory GeneratedCredentials.fromJson(Map<String, dynamic> json) {
    return GeneratedCredentials(
      loginId: json['loginId']?.toString() ?? '',
      password: json['password']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
    );
  }
}

abstract class AuthRepository {
  Future<UserModel> login(String email, String password, {bool rememberMe = true});
  Future<String> generateOfficerEmail({required String name, required String mobile, int variantIndex = 0});
  Future<String> generateOfficerPassword();
  Future<GeneratedCredentials> createOfficerAccount({
    required String name,
    required String mobile,
    required String email,
    required String password,
  });
  Future<GeneratedCredentials> createOfficerCredentials({required String name, required String mobile});
  Future<int> sendRegistrationOtp({required String name, required String mobile});
  Future<UserModel> verifyOtpAndRegister({required String name, required String mobile, required String otp});
  Future<void> logout();
  Future<UserModel?> checkAuthStatus();
}
