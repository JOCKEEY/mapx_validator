import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import '../storage/secure_storage_service.dart';

/// Creates and configures a Dio instance for API communication
class DioSetup {
  static Dio createDio({
    required SecureStorageService secureStorage,
    String? baseUrl,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        sendTimeout: ApiConstants.sendTimeout,
        contentType: ApiConstants.contentTypeJson,
        validateStatus: (status) {
          // Accept all status codes, we'll handle them in interceptors
          return true;
        },
      ),
    );

    // Add interceptors
    dio.interceptors.add(
      _AuthInterceptor(secureStorage: secureStorage),
    );

    if (kDebugMode) {
      dio.interceptors.add(
        _LoggingInterceptor(),
      );
    }

    return dio;
  }
}

/// Interceptor for handling authentication tokens
class _AuthInterceptor extends Interceptor {
  final SecureStorageService secureStorage;

  _AuthInterceptor({required this.secureStorage});

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Add auth token to request headers if available
    final token = await secureStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Handle 401 Unauthorized - token might be expired
    if (err.response?.statusCode == 401) {
      // Token expired or invalid
      // In a real app, you might try to refresh the token
      // For now, we'll just pass it through
    }

    return handler.next(err);
  }
}

/// Interceptor for logging requests and responses in debug mode
class _LoggingInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    debugPrint(
      '═══════════════════════════════════════════════════════════',
    );
    debugPrint('REQUEST: ${options.method} ${options.path}');
    debugPrint('HEADERS: ${options.headers}');
    if (options.data != null) {
      debugPrint('BODY: ${options.data}');
    }
    debugPrint(
      '═══════════════════════════════════════════════════════════',
    );

    return handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    debugPrint(
      '═══════════════════════════════════════════════════════════',
    );
    debugPrint(
      'RESPONSE: ${response.statusCode} ${response.requestOptions.path}',
    );
    debugPrint('DATA: ${response.data}');
    debugPrint(
      '═══════════════════════════════════════════════════════════',
    );

    return handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    debugPrint(
      '═══════════════════════════════════════════════════════════',
    );
    debugPrint('ERROR: ${err.requestOptions.path}');
    debugPrint('MESSAGE: ${err.message}');
    debugPrint('RESPONSE: ${err.response?.data}');
    debugPrint(
      '═══════════════════════════════════════════════════════════',
    );

    return handler.next(err);
  }
}
