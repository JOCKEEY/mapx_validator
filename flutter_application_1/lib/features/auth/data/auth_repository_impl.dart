import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/database/app_database.dart';
import '../../../core/errors/failures.dart';
import '../../../core/storage/secure_storage_service.dart';
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
  Future<Either<Failure, LoginResponseDto>> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await apiService.login(
        username: username,
        password: password,
      );

      // Save tokens to secure storage
      await secureStorage.saveAccessToken(response.accessToken);
      if (response.refreshToken != null) {
        await secureStorage.saveRefreshToken(response.refreshToken!);
      }
      if (response.expiresAt != null) {
        await secureStorage.saveTokenExpiresAt(response.expiresAt!);
      }

      // Save user info
      await secureStorage.saveUserId(response.user.id);
      await secureStorage.saveUserName(response.user.name);
      await secureStorage.saveUserEmail(response.user.email);

      // Save user session to database
      await database.upsertUserSession(
        UserSessionsCompanion(
          id: Value(response.user.id),
          userId: Value(response.user.id),
          userName: Value(response.user.name),
          userEmail: Value(response.user.email),
          accessToken: Value(response.accessToken),
          refreshToken: Value(response.refreshToken),
          tokenExpiresAt: Value(response.expiresAt),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
          lastActivityAt: Value(DateTime.now()),
        ),
      );

      return Right(response);
    } on Exception catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      // Call logout API
      await apiService.logout();

      // Clear stored tokens and user info
      await secureStorage.clearAll();

      // Clear database sessions
      final session = await database.getActiveUserSession();
      if (session != null) {
        await database.deleteUserSession(session.id);
      }

      return const Right(null);
    } on Exception catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> refreshToken() async {
    try {
      final refreshToken = await secureStorage.getRefreshToken();
      if (refreshToken == null) {
        return Left(AuthFailure.noStoredCredentials());
      }

      final newAccessToken = await apiService.refreshToken(refreshToken);

      // Save new token
      await secureStorage.saveAccessToken(newAccessToken);

      return Right(newAccessToken);
    } on Exception catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getStoredUser() async {
    try {
      final session = await database.getActiveUserSession();
      if (session == null) {
        return const Right(null);
      }

      final user = UserEntity(
        id: session.userId,
        name: session.userName,
        email: session.userEmail,
      );

      return Right(user);
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
