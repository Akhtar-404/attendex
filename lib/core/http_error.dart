// lib/core/http_error.dart
import 'package:dio/dio.dart';

String prettyDioError(Object error) {
  if (error is DioException) {
    final res = error.response;
    final code = res?.statusCode;
    final data = res?.data;

    // Try to pull a clean message from common shapes
    String msg;
    if (data is Map && data['error'] != null) {
      msg = data['error'].toString();
    } else if (data is Map && data['message'] != null) {
      msg = data['message'].toString();
    } else if (data is String) {
      msg = data;
    } else {
      msg = error.message ?? 'Network error';
    }

    return code != null ? 'HTTP $code – $msg' : msg;
  }
  return error.toString();
}
