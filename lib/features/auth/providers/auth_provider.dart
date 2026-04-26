import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth_service.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final authServiceProvider = Provider<AuthService>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return AuthService(auth: auth);
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  final service = ref.watch(authServiceProvider);
  return service.authStateChanges();
});

class AuthActionState {
  const AuthActionState({
    this.isLoading = false,
    this.errorMessage,
  });

  final bool isLoading;
  final String? errorMessage;

  AuthActionState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthActionState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthController extends StateNotifier<AuthActionState> {
  AuthController(this._authService) : super(const AuthActionState());

  final AuthService _authService;

  Future<bool> signIn({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = state.copyWith(isLoading: false, clearError: true);
      return true;
    } on AuthFailure catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Sign-in failed. Please try again.',
      );
      return false;
    }
  }

  Future<bool> signUp({required String email, required String password, required String fullName}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final credential = await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final uid = credential.user?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'profile': {
            'full_name': fullName.trim(),
          }
        }, SetOptions(merge: true));
      }
      
      state = state.copyWith(isLoading: false, clearError: true);
      return true;
    } on AuthFailure catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Sign-up failed. Please try again.',
      );
      return false;
    }
  }

  Future<bool> signOut() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authService.signOut();
      state = state.copyWith(isLoading: false, clearError: true);
      return true;
    } on AuthFailure catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Sign-out failed. Please try again.',
      );
      return false;
    }
  }

  Future<bool> forgotPassword({required String email}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authService.sendPasswordResetEmail(email: email);
      state = state.copyWith(isLoading: false, clearError: true);
      return true;
    } on AuthFailure catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Could not send reset email. Please try again.',
      );
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final credential = await _authService.signInWithGoogle();
      if (credential == null) {
        state = state.copyWith(isLoading: false, clearError: true);
        return false;
      }
      
      final user = credential.user;
      if (user != null) {
        final uid = user.uid;
        final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final data = doc.data();

        String? existingName;
        if (data != null && data['profile'] is Map) {
           existingName = (data['profile'] as Map)['full_name'] as String?;
        }

        if (existingName == null || existingName.trim().isEmpty) {
          final displayName = user.displayName ?? '';
          if (displayName.isNotEmpty) {
            await FirebaseFirestore.instance.collection('users').doc(uid).set({
              'profile': {
                'full_name': displayName,
              }
            }, SetOptions(merge: true));
          }
        }
      }
      
      state = state.copyWith(isLoading: false, clearError: true);
      return true;
    } on AuthFailure catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Google sign-in failed. Please try again.',
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthActionState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthController(authService);
});
