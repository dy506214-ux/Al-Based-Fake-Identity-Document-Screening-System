import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../security/secure_storage_service.dart';
import 'api_endpoints.dart';

final apiClientProvider = Provider((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return ApiClient(secureStorage);
});

class ApiClient {
  final Dio _dio;
  final SecureStorageService _secureStorage;

  ApiClient(this._secureStorage)
      : _dio = Dio(BaseOptions(
          baseUrl: ApiEndpoints.baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Accept': 'application/json',
          },
        )) {
    _dio.interceptors.add(_authInterceptor());
    if (kDebugMode) {
      _dio.interceptors.add(InterceptorsWrapper(
        onError: (DioException e, handler) {
          if (kIsWeb && e.type == DioExceptionType.connectionError) {
            debugPrint('[ApiClient] Notice: Render server offline or browser CORS preflight active. Using cache.');
          } else {
            debugPrint('[ApiClient] Error on ${e.requestOptions.path}: ${e.message}');
          }
          return handler.next(e);
        },
      ));
    }
  }

  Interceptor _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _secureStorage.getAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        // Only set Content-Type if request contains payload and is not FormData
        if (options.data != null && options.data is! FormData) {
          options.headers['Content-Type'] = 'application/json';
        } else if (options.data is FormData) {
          options.headers.remove('Content-Type');
        } else {
          options.headers.remove('Content-Type');
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          // Token expired or unauthorized on server: purge local invalid session
          await _secureStorage.clearTokens();
        }
        return handler.next(e);
      },
    );
  }

  Dio get dio => _dio;

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return await _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return await _dio.post(path, data: data);
  }
}
