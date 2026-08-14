import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

/// Enum for tracking auth state
enum AuthState { initial, loading, authenticated, unauthenticated, error }

/// Provides authentication state and user profile to the widget tree
class AppAuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthState _state = AuthState.initial;
  UserModel? _user;
  String? _errorMessage;

  // ── Getters ───────────────────────────────────────
  AuthState get state => _state;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get isLoading => _state == AuthState.loading;

  /// Initialize: listen to auth state changes
  AppAuthProvider() {
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _state = AuthState.unauthenticated;
      _user = null;
    } else {
      final profile = await _authService.getUserProfile(firebaseUser.uid);
      // Bug #7 fix: only mark as authenticated when profile is non-null.
      // If Firestore fetch fails, stay unauthenticated to avoid null-user crashes.
      if (profile != null) {
        _user = profile;
        _state = AuthState.authenticated;
      } else {
        _user = null;
        _state = AuthState.unauthenticated;
      }
    }
    notifyListeners();
  }

  // ── Sign Up ───────────────────────────────────────

  Future<bool> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    _setState(AuthState.loading);
    try {
      _user = await _authService.signUp(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );
      _setState(AuthState.authenticated);
      return true;
    } catch (e) {
      _errorMessage = _extractMessage(e);
      _setState(AuthState.error);
      return false;
    }
  }

  // ── Sign In ───────────────────────────────────────

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setState(AuthState.loading);
    try {
      _user = await _authService.signIn(email: email, password: password);
      _setState(AuthState.authenticated);
      return true;
    } catch (e) {
      _errorMessage = _extractMessage(e);
      _setState(AuthState.error);
      return false;
    }
  }

  // ── Sign Out ──────────────────────────────────────

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _setState(AuthState.unauthenticated);
  }

  // ── Forgot Password ───────────────────────────────

  Future<bool> sendPasswordReset(String email) async {
    // BUG-04 fix: save state so we can restore it after the async call.
    // Previously this always set state to 'unauthenticated', kicking logged-in
    // users back to the login screen when they requested a password reset.
    final previousState = _state;
    _setState(AuthState.loading);
    try {
      await _authService.sendPasswordResetEmail(email);
      // Restore prior state — the reset email was sent but the user hasn't
      // necessarily logged out.
      _setState(previousState);
      return true;
    } catch (e) {
      _errorMessage = _extractMessage(e);
      _setState(AuthState.error);
      return false;
    }
  }

  // ── Update Profile ────────────────────────────────

  Future<bool> updateProfile(UserModel updatedUser) async {
    try {
      await _authService.updateProfile(updatedUser);
      _user = updatedUser;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _extractMessage(e);
      notifyListeners();
      return false;
    }
  }

  // ── Change Password ───────────────────────────────

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _setState(AuthState.loading);
    try {
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _setState(AuthState.authenticated);
      return true;
    } catch (e) {
      _errorMessage = _extractMessage(e);
      _setState(AuthState.error);
      return false;
    }
  }

  // ── Helpers ───────────────────────────────────────

  /// Extracts a clean, human-readable message from any thrown value.
  /// Strips the 'Exception: ' prefix added by Dart's default toString.
  String _extractMessage(Object e) {
    final raw = e.toString();
    if (raw.startsWith('Exception: ')) return raw.substring('Exception: '.length);
    if (raw.startsWith('Error: ')) return raw.substring('Error: '.length);
    return raw;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setState(AuthState newState) {
    _state = newState;
    notifyListeners();
  }
}
