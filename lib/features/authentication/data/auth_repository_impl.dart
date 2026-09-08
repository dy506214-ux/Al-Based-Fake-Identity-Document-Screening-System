import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/security/secure_storage_service.dart';
import '../domain/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return AuthRepositoryImpl(apiClient, secureStorage);
});

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _apiClient;
  final SecureStorageService _secureStorage;

  AuthRepositoryImpl(this._apiClient, this._secureStorage);

  @override
  Future<void> login(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    try {
      final response = await _apiClient.post(
        ApiEndpoints.login,
        data: {'email': cleanEmail, 'password': cleanPassword},
      );

      if (response.data != null && response.data['success'] == true) {
        final token = response.data['token']?.toString();
        if (token != null && token.isNotEmpty) {
          await _secureStorage.saveTokens(
            accessToken: token,
            refreshToken: token,
          );
          return;
        }
        throw Exception('No authentication token returned by server');
      } else {
        throw Exception(response.data?['message'] ?? 'Invalid credentials');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Invalid email or password');
      } else if (e.response?.statusCode == 429) {
        throw Exception('Too many login attempts. Please wait a moment and try again.');
      } else if (e.response?.data != null && e.response?.data['message'] != null) {
        throw Exception(e.response!.data['message']);
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw Exception('Unable to reach screening server. Please verify your internet connection.');
      }
      throw Exception('Authentication failed (${e.response?.statusCode ?? 'Network'})');
    } catch (e) {
      throw Exception('Login failed: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  @override
  Future<void> logout() async {
    await _secureStorage.clearTokens();
  }

  @override
  Future<bool> checkAuthStatus() async {
    final token = await _secureStorage.getAccessToken();
    if (token == null || token.isEmpty) return false;

    // Purge known expired mock tokens or invalid debug tokens from storage
    if (token == 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjZhOGVmMjY4ZjI4YTJkNzFhYWU3NDU0MyIsInJvbGUiOiJPRkZJQ0VSIiwiaWF0IjoxNzg4NjA2Nzg5LCJleHAiOjE3ODg2OTMxODl9.3e-eZaPpnTVdrrYSwCNtXa71w611HbSdbc96HUQEQOA' ||
        token.startsWith('live_token_')) {
      await _secureStorage.clearTokens();
      return false;
    }

    return true;
  }
}
