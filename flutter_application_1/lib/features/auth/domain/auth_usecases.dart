import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failures.dart';
import 'auth_models.dart';
import 'auth_repository.dart';

/// Use case for user login
class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase({required this.repository});

  Future<Either<Failure, UserEntity>> call({
    required String emailAddress,
    required String password,
    bool rememberMe = false,
  }) async {
    if (emailAddress.isEmpty || password.isEmpty) {
      return Left(
        ValidationFailure.missingRequired('email address or password'),
      );
    }

    return await repository.login(
      emailAddress: emailAddress,
      password: password,
      rememberMe: rememberMe,
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

/// Use case for changing the current user's password
class ChangePasswordUseCase {
  final AuthRepository repository;

  ChangePasswordUseCase({required this.repository});

  Future<Either<Failure, void>> call({
    required String oldPassword,
    required String newPassword,
  }) async {
    if (oldPassword.isEmpty || newPassword.isEmpty) {
      return Left(
        ValidationFailure.missingRequired('current or new password'),
      );
    }
    if (newPassword.length < 6) {
      return Left(
        ValidationFailure('New password must be at least 6 characters.'),
      );
    }
    if (newPassword == oldPassword) {
      return Left(
        ValidationFailure(
          'New password must be different from the current password.',
        ),
      );
    }

    return await repository.changePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
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
