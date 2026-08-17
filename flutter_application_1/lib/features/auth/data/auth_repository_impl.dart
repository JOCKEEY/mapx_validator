import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/database/app_database.dart';
import '../../../core/errors/failures.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/utils/jwt_utils.dart';
import '../domain/auth_models.dart';
import '../domain/auth_repository.dart';
import 'auth_api_service.dart';

/// Implementation of AuthRepository
class AuthRepositoryImpl implements AuthRepository {
  final AuthApiService apiService;
  final SecureStorageService secureStorage;
  final AppDatabase database;

  AuthRepositoryImpl({
    required this.apiService,
    required this.secureStorage,
    required this.database,
  });

  @override
  Future<Either<Failure, UserEntity>> login({
    required String emailAddress,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      final response = await apiService.login(
        emailAddress: emailAddress,
        password: password,
        rememberMe: rememberMe,
      );

      // Only RPU validators may use this app, even if the credentials
      // themselves are valid and the API issued a token.
      if (!response.isRPUValidator) {
        return Left(
          AuthFailure(
            'This account is not authorized to use the MapX Field Validator app.',
          ),
        );
      }

      final userId = response.id.toString();
      final expiresAt = jwtExpiry(response.token);

      // Save token and user info to secure storage
      await secureStorage.saveAccessToken(response.token);
      await secureStorage.saveUserId(userId);
      await secureStorage.saveUserName(response.fullName);
      await secureStorage.saveUserEmail(response.emailAddress);
      await secureStorage.savePref(
        StorageKeys.userProfile,
        jsonEncode(response.toJson()),
      );
      if (expiresAt != null) {
        await secureStorage.saveTokenExpiresAt(expiresAt);
      } else {
        await secureStorage.delete(StorageKeys.tokenExpiresAt);
      }

      // Save user session to database
      await database.upsertUserSession(
        UserSessionsCompanion(
          id: Value(userId),
          userId: Value(userId),
          userName: Value(response.fullName),
          userEmail: Value(response.emailAddress),
          accessToken: Value(response.token),
          tokenExpiresAt: Value(expiresAt),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
          lastActivityAt: Value(DateTime.now()),
        ),
      );

      return Right(UserEntity.fromLoginResponse(response));
    } on Exception catch (e) {
      return Left(AuthFailure(_messageOf(e)));
    }
  }

  @override
  Future<Either<Failure, void>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      await apiService.updatePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      return const Right(null);
    } on Exception catch (e) {
      return Left(AuthFailure(_messageOf(e)));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      try {
        await apiService.logout();
      } on Exception {
        // Fall through: still clear local session even if the remote call fails
      }

      // Clear stored tokens and user info
      await secureStorage.clearAll();

      // Clear database sessions
      final session = await database.getActiveUserSession();
      if (session != null) {
        await database.deleteUserSession(session.id);
      }

      return const Right(null);
    } on Exception catch (e) {
      return Left(AuthFailure(_messageOf(e)));
    }
  }

  /// Strips the `Exception: ` prefix Dart adds to `Exception(message).toString()`
  String _messageOf(Exception e) =>
      e.toString().replaceFirst('Exception: ', '');

  @override
  Future<Either<Failure, UserEntity?>> getStoredUser() async {
    try {
      final profileJson = await secureStorage.getPref(StorageKeys.userProfile);
      if (profileJson == null) {
        return const Right(null);
      }

      final dto = LoginResponseDto.fromJson(
        jsonDecode(profileJson) as Map<String, dynamic>,
      );
      return Right(UserEntity.fromLoginResponse(dto));
    } on Exception catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await secureStorage.getAccessToken();
    if (token == null) return false;

    final isExpired = await secureStorage.isTokenExpired();
    return !isExpired;
  }
}
