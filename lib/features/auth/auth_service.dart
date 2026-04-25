import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';

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
    } on SocketException {
      throw const AuthFailure('No internet connection. Please try again.');
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
    } on SocketException {
      throw const AuthFailure('No internet connection. Please try again.');
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
      case 'network-request-failed':
        return const AuthFailure(
          'Network error. Check your connection and try again.',
          code: 'network-request-failed',
        );
      default:
        return AuthFailure(
          exception.message ?? 'Authentication error. Please try again.',
          code: exception.code,
        );
    }
  }
}
