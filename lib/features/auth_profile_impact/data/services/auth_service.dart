import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:savebite/shared/constants/app_constants.dart';
import 'package:savebite/features/auth_profile_impact/domain/models/user_model.dart';
import 'package:savebite/features/marketplace_surplus/data/services/merchant_service.dart';
import 'package:savebite/features/marketplace_surplus/domain/models/merchant_model.dart';

/// Authentication Service
///
/// Handles user authentication operations using Firebase Auth and Firestore.
class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get current authenticated user from Firebase Auth
  UserModel? _currentUser;

  /// Get current authenticated user
  UserModel? get currentUser => _currentUser;

  /// Get Firebase Auth user
  User? get firebaseUser => _auth.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null && _currentUser != null;

  /// Clears cached profile when Firebase Auth signs out without going through [logout].
  void clearLocalSession() {
    _currentUser = null;
  }

  /// Login with email and password
  ///
  /// 1. Authenticate with Firebase Auth
  /// 2. Fetch user document from Firestore
  /// 3. Return UserModel with role
  Future<UserModel> login(String email, String password) async {
    try {
      // Step 1: Authenticate with Firebase Auth
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception('Login failed: No user returned');
      }

      // Step 2: Fetch user document from Firestore
      final userDoc =
          await _firestore.collection('users').doc(firebaseUser.uid).get();

      if (!userDoc.exists) {
        throw Exception('User document not found. Please contact support.');
      }

      // Step 3: Convert Firestore document to UserModel
      _currentUser = UserModel.fromFirestore(
        userDoc.data()!,
        firebaseUser.uid,
      );

      return _currentUser!;
    } on FirebaseAuthException catch (e) {
      // Handle Firebase Auth specific errors
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No account found with this email. Please sign up.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address.';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          errorMessage =
              'Too many failed attempts. Please try again later.';
          break;
        case 'network-request-failed':
          errorMessage = 'Network error. Please check your connection.';
          break;
        default:
          errorMessage = 'Login failed: ${e.message ?? 'Unknown error'}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  /// Sign up new user
  ///
  /// 1. Create user in Firebase Auth
  /// 2. Create user document in Firestore 'users' collection
  /// 3. Return UserModel
  Future<UserModel> signup({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phoneE164,
    required UserRole role,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception('Sign up failed: No user returned');
      }

      final roleString = role.toString().split('.').last;

      final userData = {
        'uid': firebaseUser.uid,
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'email': email.trim(),
        'phoneNumber': phoneE164,
        'role': roleString,
        if (role == UserRole.merchant) 'merchantId': firebaseUser.uid,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(firebaseUser.uid).set(userData);

      // Create a merchant document stub so merchant profile screens can read it.
      // If this fails (e.g. Firestore rules), the merchant can still create it later
      // from the Store Profile screen.
      if (role == UserRole.merchant) {
        try {
          await MerchantService().createMerchant(
            MerchantModel(
              id: firebaseUser.uid,
              name: '',
              address: '',
              phoneNumber: '',
              email: email.trim(),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
        } catch (_) {}
      }

      _currentUser = UserModel(
        id: firebaseUser.uid,
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        email: email.trim(),
        role: role,
        phoneNumber: phoneE164,
        merchantId: role == UserRole.merchant ? firebaseUser.uid : null,
        impactData: ImpactData(
          mealsSaved: 0,
          co2Reduced: 0.0,
          moneySaved: 0.0,
          ordersCompleted: 0,
        ),
        createdAt: DateTime.now(),
      );

      return _currentUser!;
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage =
              'An account with this email already exists. Please log in instead.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address. Please enter a valid email.';
          break;
        case 'weak-password':
          errorMessage =
              'Password is too weak. Please use at least ${AppConstants.minPasswordLength} characters.';
          break;
        case 'network-request-failed':
          errorMessage =
              'Network error. Please check your internet connection and try again.';
          break;
        case 'operation-not-allowed':
          errorMessage =
              'Email/password accounts are not enabled. Please contact support.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many requests. Please try again later.';
          break;
        default:
          errorMessage =
              'Account creation failed. ${e.message ?? 'Please try again.'}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Sign up failed: ${e.toString()}');
    }
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      await _auth.signOut();
      _currentUser = null;
    } catch (e) {
      throw Exception('Logout failed: ${e.toString()}');
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No account found with this email.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address.';
          break;
        case 'network-request-failed':
          errorMessage = 'Network error. Please check your connection.';
          break;
        default:
          errorMessage =
              'Password reset failed: ${e.message ?? 'Unknown error'}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Password reset failed: ${e.toString()}');
    }
  }

  /// Update user profile
  ///
  /// Updates both Firestore document and local UserModel.
  /// Note: Address is not editable here. For consumers, use delivery address
  /// at checkout. For merchants, address is in Store Profile.
  Future<UserModel> updateProfile({
    String? name,
    String? phoneNumber,
    String? profileImage,
  }) async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        throw Exception('No user logged in');
      }

      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      String? newFirst;
      String? newLast;
      if (name != null) {
        final trimmed = name.trim();
        final parts =
            trimmed.isEmpty ? <String>[] : trimmed.split(RegExp(r'\s+'));
        newFirst = parts.isNotEmpty ? parts.first : '';
        newLast = parts.length > 1 ? parts.sublist(1).join(' ') : '';
        updateData['firstName'] = newFirst;
        updateData['lastName'] = newLast;
      }
      if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber.trim();
      if (profileImage != null) updateData['profileImage'] = profileImage;

      await _firestore.collection('users').doc(firebaseUser.uid).update(updateData);

      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(
          firstName: newFirst,
          lastName: newLast,
          phoneNumber: phoneNumber ?? _currentUser!.phoneNumber,
          profileImage: profileImage ?? _currentUser!.profileImage,
          updatedAt: DateTime.now(),
        );
      }

      return _currentUser!;
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Profile update failed: ${e.toString()}');
    }
  }

  /// Uploads a new profile image to Storage, then updates Firestore + local cache.
  Future<UserModel> updateProfileImageFromBytes(
    Uint8List bytes, {
    required String fileExtension,
    String? contentType,
  }) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      throw Exception('No user logged in');
    }
    final ext = fileExtension.startsWith('.') ? fileExtension : '.$fileExtension';
    final safeExt = _profileImageSafeExtension(ext);
    final ref = FirebaseStorage.instance
        .ref()
        .child(
          'users/${firebaseUser.uid}/profile_${DateTime.now().millisecondsSinceEpoch}$safeExt',
        );
    final ct = contentType ?? _profileImageContentTypeFromExt(safeExt);
    await ref.putData(bytes, SettableMetadata(contentType: ct));
    final url = await ref.getDownloadURL();
    return updateProfile(profileImage: url);
  }

  static String _profileImageSafeExtension(String ext) {
    final lower = ext.toLowerCase();
    if (lower.endsWith('.png')) return '.png';
    if (lower.endsWith('.webp')) return '.webp';
    if (lower.endsWith('.jpeg')) return '.jpeg';
    return '.jpg';
  }

  static String _profileImageContentTypeFromExt(String ext) {
    switch (ext.toLowerCase()) {
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.jpeg':
      case '.jpg':
      default:
        return 'image/jpeg';
    }
  }

  /// Get user by ID from Firestore
  Future<UserModel?> getUserById(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return null;
      return UserModel.fromFirestore(userDoc.data()!, userId);
    } catch (e) {
      throw Exception('Failed to fetch user: ${e.toString()}');
    }
  }

  /// Initialize auth state - check if user is already logged in
  ///
  /// Called on app startup to restore session
  Future<UserModel?> initialize() async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        _currentUser = null;
        return null;
      }

      final userDoc =
          await _firestore.collection('users').doc(firebaseUser.uid).get();

      if (!userDoc.exists) {
        _currentUser = null;
        return null;
      }

      _currentUser = UserModel.fromFirestore(
        userDoc.data()!,
        firebaseUser.uid,
      );

      return _currentUser;
    } catch (_) {
      _currentUser = null;
      return null;
    }
  }
}

