import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../security/secure_storage_service.dart';
import 'api_endpoints.dart';
import 'api_exceptions.dart';

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
          // Render free-tier cold standby can take 40-50s to spin up; 60s allows reliable connection
          connectTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 60),
          headers: {
            'Accept': 'application/json',
          },
        )) {
    _dio.interceptors.add(_authInterceptor());
    _dio.interceptors.add(_retryInterceptor());
    if (kDebugMode) {
      _dio.interceptors.add(_loggingInterceptor());
    }
  }

  /// Injects the Bearer JWT token on every protected request
  Interceptor _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _secureStorage.getAccessToken();
        if (token != null &&
            token.trim().isNotEmpty &&
            token != 'null' &&
            token != 'undefined') {
          options.headers['Authorization'] = 'Bearer ${token.trim()}';
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
          // Token expired or invalid: purge local invalid session safely
          await _secureStorage.clearTokens();
        }
        return handler.next(e);
      },
    );
  }

  /// Bounded exponential-backoff retry interceptor specifically tuned for Render cold standby
  Interceptor _retryInterceptor() {
    return InterceptorsWrapper(
      onError: (DioException err, handler) async {
        final requestOptions = err.requestOptions;

        // Never retry non-idempotent multipart uploads or if marked not to retry
        if (requestOptions.data is FormData) {
          return handler.next(err);
        }

        // Never retry client-side errors (400, 401, 403, 404, 422, 429)
        final status = err.response?.statusCode;
        if (status != null && status >= 400 && status < 500) {
          return handler.next(err);
        }

        // Check if error is transient (timeout, connection failure, 502/503/504 gateway wakeup)
        final isTimeout = err.type == DioExceptionType.connectionTimeout ||
            err.type == DioExceptionType.receiveTimeout;
        final isConnectionError = err.type == DioExceptionType.connectionError;
        final isColdStartServer = status == 502 || status == 503 || status == 504;

        if (isTimeout || isConnectionError || isColdStartServer) {
          final int retryCount = (requestOptions.extra['retry_count'] as int?) ?? 0;
          const int maxRetries = 2; // Total 3 attempts

          if (retryCount < maxRetries) {
            requestOptions.extra['retry_count'] = retryCount + 1;
            // Exponential backoff: Attempt 1 -> 2s, Attempt 2 -> 4s
            final int delayMs = (retryCount + 1) * 2000;
            if (kDebugMode) {
              debugPrint(
                  '[ApiClient] Render cold-start/transient retry (${retryCount + 1}/$maxRetries) in ${delayMs}ms for ${requestOptions.path}');
            }
            await Future.delayed(Duration(milliseconds: delayMs));

            try {
              final response = await _dio.fetch(requestOptions);
              return handler.resolve(response);
            } on DioException catch (retryErr) {
              return handler.next(retryErr);
            } catch (retryErr) {
              return handler.next(
                DioException(
                  requestOptions: requestOptions,
                  error: retryErr,
                  type: DioExceptionType.unknown,
                ),
              );
            }
          }
        }

        return handler.next(err);
      },
    );
  }

  /// Safe logging interceptor that masks passwords and token data
  Interceptor _loggingInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        debugPrint('[HTTP] ${options.method} -> ${options.uri.path}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint('[HTTP] ${response.statusCode} <- ${response.requestOptions.uri.path}');
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        final status = e.response?.statusCode;
        debugPrint('[HTTP Error] $status on ${e.requestOptions.uri.path}: ${e.message}');
        return handler.next(e);
      },
    );
  }

  Dio get dio => _dio;

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Response> post(String path, {dynamic data}) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
