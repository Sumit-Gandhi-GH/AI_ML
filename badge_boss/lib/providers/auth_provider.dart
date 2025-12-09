import 'package:flutter/foundation.dart';

/// User model for authentication
class AppUser {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? organizationId;
  final UserRole role;

  AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.organizationId,
    this.role = UserRole.staff,
  });
}

enum UserRole {
  owner,
  admin,
  staff,
}

/// Authentication provider
class AuthProvider with ChangeNotifier {
  AppUser? _currentUser;
  bool _isLoading = false;
  String? _error;

  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get userId => _currentUser?.id ?? '';
  String get organizationId => _currentUser?.organizationId ?? 'org_demo';

  AuthProvider() {
    // Auto-login for demo mode
    _loginDemo();
  }

  void _loginDemo() {
    _currentUser = AppUser(
      id: 'user_demo',
      email: 'demo@badgeboss.app',
      displayName: 'Demo User',
      organizationId: 'org_demo',
      role: UserRole.owner,
    );
    notifyListeners();
  }

  Future<void> signInWithEmail(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1));
      
      // TODO: Replace with Firebase Auth
      _currentUser = AppUser(
        id: 'user_${email.hashCode}',
        email: email,
        displayName: email.split('@').first,
        organizationId: 'org_demo',
        role: UserRole.owner,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1));
      
      // TODO: Replace with Firebase Google Auth
      _currentUser = AppUser(
        id: 'user_google',
        email: 'user@gmail.com',
        displayName: 'Google User',
        organizationId: 'org_demo',
        role: UserRole.owner,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _currentUser = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
