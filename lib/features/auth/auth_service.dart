import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthFailure implements Exception {
  const AuthFailure(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (_) {
      throw const AuthFailure('Unable to create account. Please try again.');
    }
  }

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (_) {
      throw const AuthFailure('Unable to sign in. Please try again.');
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (_) {
      throw const AuthFailure('Unable to sign out. Please try again.');
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (_) {
      throw const AuthFailure(
        'Unable to send password reset email. Please try again.',
      );
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    if (kIsWeb) {
      try {
        final provider = GoogleAuthProvider();
        return await _auth.signInWithPopup(provider);
      } on FirebaseAuthException catch (e) {
        throw _mapFirebaseAuthException(e);
      } catch (_) {
        throw const AuthFailure('Unable to sign in with Google. Please try again.');
      }
    }

    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux)) {
      throw const AuthFailure(
        'Google sign-in is not supported on this platform. Use Android, iOS, or macOS.',
      );
    }

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } on PlatformException catch (e) {
      throw _mapGoogleSignInPlatformException(e);
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (_) {
      throw const AuthFailure('Unable to sign in with Google. Please try again.');
    }
  }

  AuthFailure _mapGoogleSignInPlatformException(PlatformException exception) {
    final code = exception.code.toLowerCase();
    final message = exception.message?.toLowerCase() ?? '';

    if (code == 'network_error') {
      return const AuthFailure(
        'Network error. Check your connection and try again.',
        code: 'network_error',
      );
    }

    if (code == 'sign_in_canceled') {
      return const AuthFailure(
        'Google sign-in was canceled.',
        code: 'sign_in_canceled',
      );
    }

    if (code == 'sign_in_failed' || message.contains('apiexception: 10')) {
      return const AuthFailure(
        'Google sign-in setup is incomplete. For Android, add SHA-1/SHA-256 in Firebase and refresh google-services files. For web, verify authorized domains and Google provider settings in Firebase Auth.',
        code: 'google-sign-in-config-error',
      );
    }

    return AuthFailure(
      exception.message ?? 'Google sign-in failed. Please try again.',
      code: exception.code,
    );
  }

  AuthFailure _mapFirebaseAuthException(FirebaseAuthException exception) {
    switch (exception.code) {
      case 'email-already-in-use':
        return const AuthFailure(
          'This email is already registered. Please sign in instead.',
          code: 'email-already-in-use',
        );
      case 'invalid-email':
        return const AuthFailure(
          'Please enter a valid email address.',
          code: 'invalid-email',
        );
      case 'weak-password':
        return const AuthFailure(
          'Password is too weak. Use at least 6 characters.',
          code: 'weak-password',
        );
      case 'user-not-found':
        return const AuthFailure(
          'No account found with this email.',
          code: 'user-not-found',
        );
      case 'wrong-password':
      case 'invalid-credential':
        return const AuthFailure(
          'Incorrect email or password.',
          code: 'invalid-credential',
        );
      case 'user-disabled':
        return const AuthFailure(
          'This account has been disabled. Contact support.',
          code: 'user-disabled',
        );
      case 'too-many-requests':
        return const AuthFailure(
          'Too many attempts. Please wait and try again.',
          code: 'too-many-requests',
        );
      case 'account-exists-with-different-credential':
        return const AuthFailure(
          'An account already exists with this email using a different sign-in method.',
          code: 'account-exists-with-different-credential',
        );
      case 'network-request-failed':
        return const AuthFailure(
          'Network error. Check your connection and try again.',
          code: 'network-request-failed',
        );
      case 'popup-blocked':
        return const AuthFailure(
          'Popup was blocked by the browser. Allow popups and try again.',
          code: 'popup-blocked',
        );
      case 'popup-closed-by-user':
        return const AuthFailure(
          'Google sign-in window was closed before completing sign-in.',
          code: 'popup-closed-by-user',
        );
      case 'unauthorized-domain':
        return const AuthFailure(
          'This web domain is not authorized in Firebase Authentication settings.',
          code: 'unauthorized-domain',
        );
      case 'operation-not-allowed':
        return const AuthFailure(
          'Google sign-in is not enabled in Firebase Authentication providers.',
          code: 'operation-not-allowed',
        );
      default:
        return AuthFailure(
          exception.message ?? 'Authentication error. Please try again.',
          code: exception.code,
        );
    }
  }
}
