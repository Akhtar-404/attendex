import 'package:dio/dio.dart';
import 'config.dart';
import '../services/token_storage.dart';

final dio = Dio(BaseOptions(baseUrl: AppConfig.apiBase));
bool _attached = false;

void attachInterceptors() {
  if (_attached) return;
  _attached = true;

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Don’t add Authorization for auth endpoints
        if (!options.path.startsWith('/auth/')) {
          final token = await TokenStorage.readAccess();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        handler.next(options);
      },
    ),
  );
}
