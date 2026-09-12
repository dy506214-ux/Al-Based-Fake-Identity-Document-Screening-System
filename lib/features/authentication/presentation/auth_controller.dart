import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exceptions.dart';
import '../data/auth_repository_impl.dart';
import '../domain/auth_repository.dart';
import '../domain/user_model.dart';

enum AuthStateStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStateStatus status;
  final String? errorMessage;
  final UserModel? user;

  const AuthState({
    this.status = AuthStateStatus.initial,
    this.errorMessage,
    this.user,
  });

  AuthState copyWith({
    AuthStateStatus? status,
    String? errorMessage,
    UserModel? user,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      user: user ?? this.user,
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
    Future.microtask(() => checkAuthStatus());
    return const AuthState();
  }

  Future<void> checkAuthStatus() async {
    state = state.copyWith(status: AuthStateStatus.loading);
    try {
      final user = await _authRepository.checkAuthStatus();
      if (user != null) {
        state = state.copyWith(status: AuthStateStatus.authenticated, user: user);
      } else {
        state = state.copyWith(status: AuthStateStatus.unauthenticated, user: null);
      }
    } catch (e) {
      final message = ApiException.extractUserMessage(e);
      state = state.copyWith(status: AuthStateStatus.error, errorMessage: message);
    }
  }

  Future<void> login(String email, String password, {bool rememberMe = true}) async {
    if (state.status == AuthStateStatus.loading) return;

    state = state.copyWith(status: AuthStateStatus.loading, errorMessage: null);
    try {
      final user = await _authRepository.login(email, password, rememberMe: rememberMe);
      state = state.copyWith(status: AuthStateStatus.authenticated, user: user);
    } catch (e) {
      final message = ApiException.extractUserMessage(e);
      state = state.copyWith(status: AuthStateStatus.error, errorMessage: message);
    }
  }

  Future<String> generateOfficerEmail({
    required String name,
    required String mobile,
    int variantIndex = 0,
  }) async {
    try {
      return await _authRepository.generateOfficerEmail(
        name: name,
        mobile: mobile,
        variantIndex: variantIndex,
      );
    } catch (e) {
      final message = ApiException.extractUserMessage(e);
      state = state.copyWith(status: AuthStateStatus.error, errorMessage: message);
      rethrow;
    }
  }

  Future<String> generateOfficerPassword({String? name}) async {
    try {
      return await _authRepository.generateOfficerPassword(name: name);
    } catch (e) {
      final message = ApiException.extractUserMessage(e);
      state = state.copyWith(status: AuthStateStatus.error, errorMessage: message);
      rethrow;
    }
  }

  Future<GeneratedCredentials> createOfficerAccount({
    required String name,
    required String mobile,
    required String email,
    required String password,
  }) async {
    try {
      return await _authRepository.createOfficerAccount(
        name: name,
        mobile: mobile,
        email: email,
        password: password,
      );
    } catch (e) {
      final message = ApiException.extractUserMessage(e);
      state = state.copyWith(status: AuthStateStatus.error, errorMessage: message);
      rethrow;
    }
  }

  Future<GeneratedCredentials> createOfficerCredentials({
    required String name,
    required String mobile,
  }) async {
    try {
      return await _authRepository.createOfficerCredentials(
        name: name,
        mobile: mobile,
      );
    } catch (e) {
      final message = ApiException.extractUserMessage(e);
      state = state.copyWith(status: AuthStateStatus.error, errorMessage: message);
      rethrow;
    }
  }

  Future<int> sendRegistrationOtp({required String name, required String mobile}) async {
    try {
      return await _authRepository.sendRegistrationOtp(name: name, mobile: mobile);
    } catch (e) {
      final message = ApiException.extractUserMessage(e);
      state = state.copyWith(status: AuthStateStatus.error, errorMessage: message);
      rethrow;
    }
  }

  Future<void> verifyOtpAndRegister({
    required String name,
    required String mobile,
    required String otp,
  }) async {
    if (state.status == AuthStateStatus.loading) return;

    state = state.copyWith(status: AuthStateStatus.loading, errorMessage: null);
    try {
      final user = await _authRepository.verifyOtpAndRegister(
        name: name,
        mobile: mobile,
        otp: otp,
      );
      state = state.copyWith(status: AuthStateStatus.authenticated, user: user);
    } catch (e) {
      final message = ApiException.extractUserMessage(e);
      state = state.copyWith(status: AuthStateStatus.error, errorMessage: message);
      rethrow;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(status: AuthStateStatus.loading);
    try {
      await _authRepository.logout();
      state = state.copyWith(status: AuthStateStatus.unauthenticated, user: null);
    } catch (e) {
      final message = ApiException.extractUserMessage(e);
      state = state.copyWith(status: AuthStateStatus.error, errorMessage: message);
    }
  }
}
