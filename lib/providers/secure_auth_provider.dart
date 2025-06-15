import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/secure_auth_service.dart';

// Secure Auth state class
class SecureAuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool biometricEnabled;
  final bool biometricAvailable;

  const SecureAuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.biometricEnabled = false,
    this.biometricAvailable = false,
  });

  SecureAuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? biometricEnabled,
    bool? biometricAvailable,
  }) {
    return SecureAuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      biometricAvailable: biometricAvailable ?? this.biometricAvailable,
    );
  }

  bool get isLoggedIn => user != null;
}

// Secure Auth notifier
class SecureAuthNotifier extends StateNotifier<SecureAuthState> {
  final SecureAuthService _authService;

  SecureAuthNotifier(this._authService) : super(const SecureAuthState()) {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    state = state.copyWith(isLoading: true);

    try {
      // Initialize auth service and load persisted data
      await _authService.initialize();
      
      if (_authService.isLoggedIn) {
        final user = _authService.currentUser;
        final biometricAvailable = _authService.biometricEnabled;
        final biometricEnabled = user != null 
            ? await _authService.isBiometricEnabled(user.email)
            : false;
            
        state = state.copyWith(
          user: user, 
          isLoading: false,
          biometricAvailable: biometricAvailable,
          biometricEnabled: biometricEnabled,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          biometricAvailable: _authService.biometricEnabled,
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _authService.login(email, password);
      final biometricEnabled = await _authService.isBiometricEnabled(user.email);
      
      state = state.copyWith(
        user: user, 
        isLoading: false,
        biometricEnabled: biometricEnabled,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> loginWithBiometrics() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _authService.authenticateWithBiometrics();
      if (user != null) {
        state = state.copyWith(user: user, isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          error: 'Biometric authentication failed', 
          isLoading: false,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> register(String email, String password, String name) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _authService.register(email, password, name);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> enableBiometric() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await _authService.enableBiometric();
      if (success) {
        state = state.copyWith(
          biometricEnabled: true, 
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          error: 'Failed to enable biometric authentication', 
          isLoading: false,
        );
      }
      return success;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await _authService.changePassword(currentPassword, newPassword);
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);

    try {
      await _authService.logout();
      state = const SecureAuthState(
        biometricAvailable: _authService.biometricEnabled,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  void updateProfile({String? name, String? email, String? profilePicture}) {
    if (state.user != null) {
      final updatedUser = state.user!.copyWith(
        name: name,
        email: email,
        profilePicture: profilePicture,
      );
      state = state.copyWith(user: updatedUser);
      
      // Update the auth service as well
      _authService.updateUserData(updatedUser);
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Providers
final secureAuthServiceProvider = Provider<SecureAuthService>((ref) {
  return SecureAuthService();
});

final secureAuthProvider = StateNotifierProvider<SecureAuthNotifier, SecureAuthState>((ref) {
  final authService = ref.watch(secureAuthServiceProvider);
  return SecureAuthNotifier(authService);
});

// Convenience providers
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(secureAuthProvider).user;
});

final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(secureAuthProvider).isLoggedIn;
});

final authLoadingProvider = Provider<bool>((ref) {
  return ref.watch(secureAuthProvider).isLoading;
});

final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(secureAuthProvider).error;
});

final biometricAvailableProvider = Provider<bool>((ref) {
  return ref.watch(secureAuthProvider).biometricAvailable;
});

final biometricEnabledProvider = Provider<bool>((ref) {
  return ref.watch(secureAuthProvider).biometricEnabled;
}); 