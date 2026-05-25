import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:savebite/features/auth_profile_impact/data/services/auth_service.dart';
import 'package:savebite/features/auth_profile_impact/domain/models/user_model.dart';

/// Authentication Provider
///
/// Manages authentication state across the app.
class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profileSubscription;

  /// Real-time mirror of [`users/{uid}`] ([impactData], profile fields updated by Functions).
  Future<void> _subscribeUserDocumentStream(String uid) async {
    await _profileSubscription?.cancel();
    _profileSubscription = null;

    if (uid.isEmpty) return;

    _profileSubscription =
        FirebaseFirestore.instance.collection('users').doc(uid).snapshots().listen(
      (snapshot) {
        if (!snapshot.exists || snapshot.data() == null) return;
        try {
          _currentUser =
              UserModel.fromFirestore(snapshot.data()!, uid);
          notifyListeners();
        } catch (e, st) {
          if (kDebugMode) {
            debugPrint('[AuthProvider] users/$uid snapshot parse failed: $e');
            debugPrint('$st');
          }
        }
      },
      onError: (Object e, StackTrace st) {
        if (kDebugMode) {
          debugPrint('[AuthProvider] users/$uid snapshot error: $e');
          debugPrint('$st');
        }
      },
    );
  }

  Future<void> _cancelUserDocumentStream() async {
    await _profileSubscription?.cancel();
    _profileSubscription = null;
  }

  Future<void> _handleAuthUserChanged(User? user) async {
    if (user == null) {
      await _cancelUserDocumentStream();
      if (_currentUser != null) {
        _authService.clearLocalSession();
        _currentUser = null;
        notifyListeners();
      }
      return;
    }
    await _subscribeUserDocumentStream(user.uid);
  }

  // Getters
  UserModel? get currentUser => _currentUser;

  /// True when Firebase Auth has a user (source of truth for “signed in” redirects).
  bool get hasFirebaseSession => _authService.firebaseUser != null;

  /// Full session: Firebase user + Firestore profile loaded (checkout / profile UI).
  bool get isAuthenticated =>
      _authService.firebaseUser != null && _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserRole? get userRole => _currentUser?.role;

  /// Initialize auth state
  ///
  /// Check if user is already logged in via Firebase Auth
  Future<void> initialize() async {
    await _authSubscription?.cancel();

    _isLoading = true;
    notifyListeners();

    try {
      await _cancelUserDocumentStream();
      _currentUser = await _authService.initialize();
      final uid = _authService.firebaseUser?.uid;
      if (_currentUser != null && uid != null) {
        await _subscribeUserDocumentStream(uid);
      }
      _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
        (User? user) {
          unawaited(_handleAuthUserChanged(user));
        },
      );
    } catch (e) {
      _errorMessage = e.toString();
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Login with email and password
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.login(email, password);
      final uid = _authService.firebaseUser?.uid;
      if (uid != null) {
        await _subscribeUserDocumentStream(uid);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign up new user
  Future<bool> signup({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phoneE164,
    required UserRole role,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.signup(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        phoneE164: phoneE164,
        role: role,
      );
      final uid = _authService.firebaseUser?.uid;
      if (uid != null) {
        await _subscribeUserDocumentStream(uid);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout current user
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
      await _cancelUserDocumentStream();
      _currentUser = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reset password
  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.resetPassword(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update user profile
  Future<bool> updateProfile({
    String? name,
    String? phoneNumber,
    String? profileImage,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.updateProfile(
        name: name,
        phoneNumber: phoneNumber,
        profileImage: profileImage,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Pick image bytes are uploaded to Firebase Storage; Firestore [profileImage] is updated.
  Future<bool> updateProfileImageFromBytes(
    Uint8List bytes, {
    required String fileExtension,
    String? contentType,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.updateProfileImageFromBytes(
        bytes,
        fileExtension: fileExtension,
        contentType: contentType,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update impact data
  void updateImpactData(ImpactData newImpactData) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(impactData: newImpactData);
      notifyListeners();
    }
  }

  /// Reload [users/{uid}] from Firestore (sustainability totals, etc.).
  Future<void> refreshUserProfile() async {
    final u = await _authService.refreshCurrentUserProfile();
    if (u != null) {
      _currentUser = u;
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    unawaited(_cancelUserDocumentStream());
    super.dispose();
  }
}

