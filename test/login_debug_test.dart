// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:document_screening/core/network/api_endpoints.dart';

void main() {
  test('Detailed Dio Probe', () async {
    final dio = Dio(BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Accept': 'application/json'},
    ));

    try {
      print('Sending Dio POST to ${ApiEndpoints.baseUrl}/api/auth/login...');
      final response = await dio.post(
        '/api/auth/login',
        data: {'email': 'officer@test.com', 'password': '123456'},
      );
      print('Success: ${response.statusCode} -> ${response.data}');
    } on DioException catch (e) {
      print('=== DIO EXCEPTION DETAILS ===');
      print('Type: ${e.type}');
      print('Message: ${e.message}');
      print('Error: ${e.error}');
      print('Error RuntimeType: ${e.error.runtimeType}');
      print('Response: ${e.response}');
      print('StackTrace: ${e.stackTrace}');
      print('=============================');
    } catch (e, st) {
      print('Generic Exception: $e\n$st');
    }
  });
}
