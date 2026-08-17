import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failures.dart';
import '../domain/auth_models.dart';

/// Repository contract for authentication operations
abstract class AuthRepository {
  /// Attempt to login with credentials
  Future<Either<Failure, LoginResponseDto>> login({
    required String username,
    required String password,
  });

  /// Logout the current user
  Future<Either<Failure, void>> logout();

  /// Refresh authentication token
  Future<Either<Failure, String>> refreshToken();

  /// Get stored credentials
  Future<Either<Failure, UserEntity?>> getStoredUser();

  /// Check if user is authenticated
  Future<bool> isAuthenticated();
}
