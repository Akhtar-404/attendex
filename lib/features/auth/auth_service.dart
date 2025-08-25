// lib/features/auth/auth_service.dart
import 'package:dio/dio.dart';
import '../../core/dio_client.dart';

class AuthFailure implements Exception {
  final int? code;
  final String message;
  AuthFailure(this.message, {this.code});
  @override
  String toString() => 'AuthFailure($code): $message';
}

class AuthService {
  AuthService() {
    attachInterceptors(); // uses your existing dio_client setup
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final resp = await dio.post(
        '/auth/login',
        data: {'email': email.trim().toLowerCase(), 'password': password},
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );
      return Map<String, dynamic>.from(resp.data as Map);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final data = e.response?.data;
      final msg = (data is Map && data['error'] is String)
          ? data['error'] as String
          : (e.message ?? 'Login failed');
      throw AuthFailure(msg, code: code);
    }
  }

  Future<Map<String, dynamic>> signup(
    String name,
    String email,
    String password, {
    String role = 'EMPLOYEE',
  }) async {
    try {
      final resp = await dio.post(
        '/auth/signup',
        data: {
          'name': name.trim(),
          'email': email.trim().toLowerCase(),
          'password': password,
          'role': role, // backend ignores/validates; default EMPLOYEE
        },
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );
      return Map<String, dynamic>.from(resp.data as Map);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final data = e.response?.data;
      final msg = (data is Map && data['error'] is String)
          ? data['error'] as String
          : (e.message ?? 'Signup failed');
      throw AuthFailure(msg, code: code);
    }
  }
}
