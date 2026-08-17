import 'package:dio/dio.dart';

import '../../../core/constants/app_constants.dart';
import '../domain/auth_models.dart';

/// API service for authentication endpoints
class AuthApiService {
  final Dio dio;

  AuthApiService({required this.dio});

  /// Call login endpoint
  Future<LoginResponseDto> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await dio.post(
        ApiConstants.loginEndpoint,
        data: {
          'username': username,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        return LoginResponseDto.fromJson(response.data);
      } else {
        throw Exception('Login failed with status ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Login request failed: ${e.message}');
    }
  }

  /// Call logout endpoint
  Future<void> logout() async {
    try {
      await dio.post(ApiConstants.logoutEndpoint);
    } on DioException catch (e) {
      throw Exception('Logout request failed: ${e.message}');
    }
  }

  /// Call refresh token endpoint
  Future<String> refreshToken(String currentRefreshToken) async {
    try {
      final response = await dio.post(
        ApiConstants.refreshTokenEndpoint,
        data: {
          'refresh_token': currentRefreshToken,
        },
      );

      if (response.statusCode == 200) {
        return response.data['access_token'] as String;
      } else {
        throw Exception('Refresh token failed with status ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Refresh token request failed: ${e.message}');
    }
  }
}
