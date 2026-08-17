import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/app_providers.dart';
import '../../domain/auth_models.dart';
import '../../domain/auth_usecases.dart';

/// Auth state - represents the current authentication state
class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final UserEntity? user;
  final String? errorMessage;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.errorMessage,
  });

  const AuthState.unauthenticated()
      : isLoading = false,
        isAuthenticated = false,
        user = null,
        errorMessage = null;

  const AuthState.loading()
      : isLoading = true,
        isAuthenticated = false,
        user = null,
        errorMessage = null;

  AuthState.authenticated(this.user)
      : isLoading = false,
        isAuthenticated = true,
        errorMessage = null;

  AuthState.error(String message)
      : isLoading = false,
        isAuthenticated = false,
        user = null,
        errorMessage = message;
}

/// Auth state notifier
class AuthStateNotifier extends StateNotifier<AuthState> {
  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;

  AuthStateNotifier({
    required LoginUseCase loginUseCase,
    required LogoutUseCase logoutUseCase,
  })  : _loginUseCase = loginUseCase,
        _logoutUseCase = logoutUseCase,
        super(const AuthState.unauthenticated());

  /// Attempt to login with the given credentials. Returns true on success.
  Future<bool> login({
    required String emailAddress,
    required String password,
    bool rememberMe = false,
  }) async {
    state = const AuthState.loading();

    final result = await _loginUseCase(
      emailAddress: emailAddress,
      password: password,
      rememberMe: rememberMe,
    );

    return result.match(
      (failure) {
        state = AuthState.error(failure.message);
        return false;
      },
      (user) {
        state = AuthState.authenticated(user);
        return true;
      },
    );
  }

  Future<void> logout() async {
    await _logoutUseCase();
    state = const AuthState.unauthenticated();
  }
}

/// Auth state provider
final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier(
    loginUseCase: ref.watch(loginUseCaseProvider),
    logoutUseCase: ref.watch(logoutUseCaseProvider),
  );
});
