import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/auth_models.dart';

/// Auth state - represents the current authentication state
class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final UserEntity? user;
  final String? accessToken;
  final String? errorMessage;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.accessToken,
    this.errorMessage,
  });

  const AuthState.unauthenticated()
      : isLoading = false,
        isAuthenticated = false,
        user = null,
        accessToken = null,
        errorMessage = null;

  const AuthState.loading()
      : isLoading = true,
        isAuthenticated = false,
        user = null,
        accessToken = null,
        errorMessage = null;

  AuthState.authenticated({required UserEntity user, required String accessToken})
      : isLoading = false,
        isAuthenticated = true,
        user = user,
        accessToken = accessToken,
        errorMessage = null;
}

/// Auth state notifier
class AuthStateNotifier extends StateNotifier<AuthState> {
  AuthStateNotifier() : super(const AuthState.unauthenticated());

  void setLoading() {
    state = const AuthState.loading();
  }

  void setAuthenticated(UserEntity user, String token) {
    state = AuthState.authenticated(user: user, accessToken: token);
  }

  void setUnauthenticated() {
    state = const AuthState.unauthenticated();
  }
}

/// Auth state provider
final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier();
});
