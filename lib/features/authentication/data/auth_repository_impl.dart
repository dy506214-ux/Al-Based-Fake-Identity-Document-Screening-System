import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/security/secure_storage_service.dart';
import '../domain/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  // final apiClient = ref.watch(apiClientProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return AuthRepositoryImpl(secureStorage);
});

class AuthRepositoryImpl implements AuthRepository {
  final SecureStorageService _secureStorage;

  AuthRepositoryImpl(this._secureStorage);

  @override
  Future<void> login(String email, String password) async {
    try {
      // Because we are using the requested existing backend, we simulate login if backend is not available
      // or directly use the Dio call.
      
      // Real API Call (Mocked response for now if the endpoint is not fully active, but structured for real)
      /* 
      final response = await _apiClient.dio.post(ApiEndpoints.login, data: {
        'email': email,
        'password': password,
      });
      final accessToken = response.data['accessToken'];
      final refreshToken = response.data['refreshToken'];
      */
      
      // MOCK IMPLEMENTATION (Simulating backend latency)
      await Future.delayed(const Duration(seconds: 2));
      if (email == 'admin' && password == 'admin') {
         await _secureStorage.saveTokens(
           accessToken: 'mock_access_token_123',
           refreshToken: 'mock_refresh_token_456'
         );
      } else {
         throw Exception('Invalid credentials');
      }

    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  @override
  Future<void> logout() async {
    await _secureStorage.clearTokens();
  }

  @override
  Future<bool> checkAuthStatus() async {
    final token = await _secureStorage.getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
