import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failures.dart';
import 'auth_models.dart';

/// Repository contract for authentication operations
abstract class AuthRepository {
  /// Attempt to login with credentials
  Future<Either<Failure, UserEntity>> login({
    required String emailAddress,
    required String password,
    bool rememberMe = false,
  });

  /// Logout the current user
  Future<Either<Failure, void>> logout();

  /// Change the current user's password
  Future<Either<Failure, void>> changePassword({
    required String oldPassword,
    required String newPassword,
  });

  /// Get stored credentials
  Future<Either<Failure, UserEntity?>> getStoredUser();

  /// Check if user is authenticated
  Future<bool> isAuthenticated();
}
