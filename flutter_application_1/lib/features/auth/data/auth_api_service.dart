import 'package:dio/dio.dart';

import '../../../core/constants/app_constants.dart';
import '../domain/auth_models.dart';

/// API service for authentication endpoints
class AuthApiService {
  final Dio dio;

  AuthApiService({required this.dio});

  /// Call login endpoint
  Future<LoginResponseDto> login({
    required String emailAddress,
    required String password,
    bool rememberMe = false,
  }) async {
    late final Response response;
    try {
      response = await dio.post(
        ApiConstants.loginEndpoint,
        data: {
          'emailAddress': emailAddress,
          'password': password,
          'rememberMe': rememberMe,
        },
      );
    } on DioException catch (e) {
      throw Exception('Login request failed: ${e.message}');
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      return LoginResponseDto.fromJson(response.data as Map<String, dynamic>);
    }

    throw Exception(_extractErrorMessage(response));
  }

  /// Call logout endpoint
  Future<void> logout() async {
    try {
      await dio.post(ApiConstants.logoutEndpoint);
    } on DioException catch (e) {
      throw Exception('Logout request failed: ${e.message}');
    }
  }

  /// Call change-password endpoint
  Future<void> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    late final Response response;
    try {
      response = await dio.post(
        ApiConstants.updatePasswordEndpoint,
        data: {
          'password': newPassword,
          'oldpassword': oldPassword,
        },
      );
    } on DioException catch (e) {
      throw Exception('Change password request failed: ${e.message}');
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    }

    throw Exception(_extractErrorMessage(response));
  }

  /// Extract a human-readable error message from a failed response
  String _extractErrorMessage(Response response) {
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'] ?? data['error'] ?? data['error_description'];
      if (message != null) return message.toString();
    }
    return 'Login failed with status ${response.statusCode}';
  }
}
