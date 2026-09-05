import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository_impl.dart';
import '../domain/auth_repository.dart';

enum AuthStateStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStateStatus status;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStateStatus.initial,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStateStatus? status,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(() {
  return AuthController();
});

class AuthController extends Notifier<AuthState> {
  late final AuthRepository _authRepository;

  @override
  AuthState build() {
    _authRepository = ref.watch(authRepositoryProvider);
    // We can't safely perform async side effects directly in build without returning Future,
    // so we return initial state and then fire the check.
    Future.microtask(() => checkAuthStatus());
    return const AuthState();
  }

  Future<void> checkAuthStatus() async {
    state = state.copyWith(status: AuthStateStatus.loading);
    try {
      final isAuthenticated = await _authRepository.checkAuthStatus();
      if (isAuthenticated) {
        state = state.copyWith(status: AuthStateStatus.authenticated);
      } else {
        state = state.copyWith(status: AuthStateStatus.unauthenticated);
      }
    } catch (e) {
      state = state.copyWith(status: AuthStateStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStateStatus.loading, errorMessage: null);
    try {
      await _authRepository.login(email, password);
      state = state.copyWith(status: AuthStateStatus.authenticated);
    } catch (e) {
      state = state.copyWith(status: AuthStateStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> logout() async {
    state = state.copyWith(status: AuthStateStatus.loading);
    try {
      await _authRepository.logout();
      state = state.copyWith(status: AuthStateStatus.unauthenticated);
    } catch (e) {
      state = state.copyWith(status: AuthStateStatus.error, errorMessage: e.toString());
    }
  }
}
