import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

class UserState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  UserState({this.user, required this.isLoading, this.error});

  bool get isAuthenticated => user != null;

  UserState copyWith({UserModel? user, bool? isLoading, String? error}) {
    return UserState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class UserNotifier extends StateNotifier<UserState> {
  final AuthService _authService;

  UserNotifier(this._authService) : super(UserState(isLoading: false)) {
    _authService.authStateChanges.listen((User? firebaseUser) {
      if (firebaseUser != null) {
        _fetchUserData(firebaseUser.uid);
      } else {
        state = state.copyWith(user: null);
      }
    });
  }

  Future<void> _fetchUserData(String uid) async {
    state = state.copyWith(isLoading: true);

    try {
      final user = await _authService.getUserData(uid);
      state = state.copyWith(user: user, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(user: null, isLoading: false, error: e.toString());
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
        fullName: fullName,
      );

      state = state.copyWith(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      state = state.copyWith(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.signOut();
    state = state.copyWith(user: null);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<UserModel?> signInWithGoogle() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final user = await _authService.signInWithGoogle();
      state = state.copyWith(user: user, isLoading: false);
      return user;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return UserNotifier(authService);
});
