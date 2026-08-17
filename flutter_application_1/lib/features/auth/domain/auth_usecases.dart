import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failures.dart';
import '../domain/auth_models.dart';
import '../domain/auth_repository.dart';

/// Use case for user login
class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase({required this.repository});

  Future<Either<Failure, LoginResponseDto>> call({
    required String username,
    required String password,
  }) async {
    // Validate input
    if (username.isEmpty || password.isEmpty) {
      return Left(ValidationFailure.missingRequired('username or password'));
    }

    return await repository.login(
      username: username,
      password: password,
    );
  }
}

/// Use case for user logout
class LogoutUseCase {
  final AuthRepository repository;

  LogoutUseCase({required this.repository});

  Future<Either<Failure, void>> call() async {
    return await repository.logout();
  }
}

/// Use case for refreshing authentication token
class RefreshTokenUseCase {
  final AuthRepository repository;

  RefreshTokenUseCase({required this.repository});

  Future<Either<Failure, String>> call() async {
    return await repository.refreshToken();
  }
}

/// Use case for getting stored user info
class GetStoredUserUseCase {
  final AuthRepository repository;

  GetStoredUserUseCase({required this.repository});

  Future<Either<Failure, UserEntity?>> call() async {
    return await repository.getStoredUser();
  }
}

/// Use case for checking authentication status
class CheckAuthStatusUseCase {
  final AuthRepository repository;

  CheckAuthStatusUseCase({required this.repository});

  Future<bool> call() async {
    return await repository.isAuthenticated();
  }
}
