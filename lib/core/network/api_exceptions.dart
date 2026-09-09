import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Base structured exception for all network and API failures in the app.
sealed class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  const ApiException(this.message, {this.statusCode, this.details});

  @override
  String toString() => message;

  /// Translates raw DioException or any exception into a structured, user-safe [ApiException].
  factory ApiException.fromDioException(DioException e) {
    // 1. Check HTTP response status codes
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;
    String? serverMessage;

    if (data is Map) {
      serverMessage = (data['message'] ?? data['error'])?.toString();
    } else if (data is String && data.isNotEmpty && !data.startsWith('<!DOCTYPE')) {
      serverMessage = data;
    }

    if (statusCode != null) {
      switch (statusCode) {
        case 400:
          return ValidationException(
            serverMessage ?? 'Invalid request. Please verify your input.',
            statusCode: 400,
            details: data,
          );
        case 401:
          return UnauthorizedException(
            serverMessage ?? 'Invalid email or password, or your session is unauthorized.',
            statusCode: 401,
          );
        case 403:
          return ForbiddenException(
            serverMessage ?? 'You are not authorized to access this application.',
            statusCode: 403,
          );
        case 404:
          return NotFoundException(
            serverMessage ?? 'Requested authentication service was not found.',
            statusCode: 404,
          );
        case 413:
          return ValidationException(
            'File size exceeds the server limit. Please upload a smaller image.',
            statusCode: 413,
          );
        case 422:
          return ValidationException(
            serverMessage ?? 'Please check the entered information.',
            statusCode: 422,
            details: data,
          );
        case 429:
          return RateLimitException(
            serverMessage ?? 'Too many requests. Please wait a moment and try again.',
            statusCode: 429,
          );
        case 502:
        case 503:
        case 504:
          return ServerColdStartException(
            serverMessage ?? 'Screening server is temporarily waking up / unavailable. Please try again in a few seconds.',
            statusCode: statusCode,
          );
        case 500:
        default:
          return ServerException(
            serverMessage ?? 'Screening server encountered an internal error.',
            statusCode: statusCode,
          );
      }
    }

    // 2. Check transport/connection level errors
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return const TimeoutException(
          'Connection timed out. Server response timed out. Please try again.',
        );

      case DioExceptionType.connectionError:
        // Detect offline or DNS resolution errors
        if (!kIsWeb && e.error is SocketException) {
          final se = e.error as SocketException;
          final osMsg = se.osError?.message.toLowerCase() ?? '';
          if (osMsg.contains('network') || osMsg.contains('unreachable') || osMsg.contains('host')) {
            return const NoInternetException();
          }
        }
        if (kIsWeb) {
          return const NetworkException(
            'Browser cross-origin restriction (CORS) prevented direct connection to screening server. Run on Android or launch Chrome with --disable-web-security.',
          );
        }
        return const ServerUnreachableException(
          'Screening server is temporarily unavailable. Please try again.',
        );

      case DioExceptionType.cancel:
        return const RequestCancelledException();

      case DioExceptionType.badCertificate:
        return const SecurityException('Secure SSL connection could not be established.');

      default:
        return UnknownApiException(
          serverMessage ?? 'An unexpected network issue occurred. Please try again.',
        );
    }
  }

  /// Converts an arbitrary error or exception into a user-facing error message string.
  static String extractUserMessage(dynamic error) {
    if (error is ApiException) {
      return error.message;
    }
    if (error is DioException) {
      return ApiException.fromDioException(error).message;
    }
    final raw = error.toString().replaceAll('Exception: ', '').trim();
    if (raw.isEmpty || raw.contains('DioException')) {
      return 'An unexpected error occurred. Please check your connection and try again.';
    }
    return raw;
  }
}

class NoInternetException extends ApiException {
  const NoInternetException([super.message = 'No internet connection. Please check your connection.']);
}

class NetworkException extends ApiException {
  const NetworkException([super.message = 'A network error occurred. Please check your connection.']);
}

class ParseException extends ApiException {
  const ParseException([super.message = 'Failed to parse response from screening server.']);
}

class ServerColdStartException extends ApiException {
  const ServerColdStartException(super.message, {super.statusCode});
}

class ServerUnreachableException extends ApiException {
  const ServerUnreachableException([super.message = 'Screening server is temporarily unavailable. Please try again.']);
}

class TimeoutException extends ApiException {
  const TimeoutException([super.message = 'Connection timed out. Server response timed out. Please try again.']);
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException(
    super.message, {
    super.statusCode = 401,
  });
}

class ForbiddenException extends ApiException {
  const ForbiddenException(super.message, {super.statusCode = 403});
}

class NotFoundException extends ApiException {
  const NotFoundException(super.message, {super.statusCode = 404});
}

class ValidationException extends ApiException {
  const ValidationException(super.message, {super.statusCode = 400, super.details});
}

class RateLimitException extends ApiException {
  const RateLimitException(super.message, {super.statusCode = 429});
}

class ServerException extends ApiException {
  const ServerException(super.message, {super.statusCode = 500});
}

class RequestCancelledException extends ApiException {
  const RequestCancelledException([super.message = 'Request was cancelled.']);
}

class SecurityException extends ApiException {
  const SecurityException(super.message);
}

class UnknownApiException extends ApiException {
  const UnknownApiException(super.message);
}
