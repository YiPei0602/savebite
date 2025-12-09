import '../models/user_model.dart';

/// Authentication Service
/// 
/// Handles user authentication operations.
/// Currently uses mock data. Will be replaced with Firebase Auth.
class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Mock current user
  UserModel? _currentUser;

  /// Get current authenticated user
  UserModel? get currentUser => _currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => _currentUser != null;

  /// Login with email and password
  /// 
  /// TODO: Replace with Firebase Auth
  Future<UserModel> login(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Mock authentication
    _currentUser = UserModel(
      id: 'user_001',
      name: 'John Doe',
      email: email,
      role: UserRole.consumer,
      profileImage: null,
      phoneNumber: '+60123456789',
      address: 'Tower 1B, Ideal Residency, Penang',
      impactData: ImpactData(
        mealsSaved: 42,
        co2Reduced: 105.0,
        moneySaved: 420.50,
        ordersCompleted: 15,
      ),
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
    );

    return _currentUser!;
  }

  /// Sign up new user
  /// 
  /// TODO: Replace with Firebase Auth
  Future<UserModel> signup({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Mock user creation
    _currentUser = UserModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      role: role,
      profileImage: null,
      impactData: ImpactData(
        mealsSaved: 0,
        co2Reduced: 0.0,
        moneySaved: 0.0,
        ordersCompleted: 0,
      ),
      createdAt: DateTime.now(),
    );

    return _currentUser!;
  }

  /// Logout current user
  /// 
  /// TODO: Replace with Firebase Auth
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = null;
  }

  /// Reset password
  /// 
  /// TODO: Replace with Firebase Auth
  Future<void> resetPassword(String email) async {
    await Future.delayed(const Duration(seconds: 1));
    // Mock password reset
  }

  /// Update user profile
  /// 
  /// TODO: Replace with Firebase Firestore
  Future<UserModel> updateProfile({
    String? name,
    String? phoneNumber,
    String? address,
    String? profileImage,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    if (_currentUser == null) {
      throw Exception('No user logged in');
    }

    _currentUser = _currentUser!.copyWith(
      name: name ?? _currentUser!.name,
      phoneNumber: phoneNumber ?? _currentUser!.phoneNumber,
      address: address ?? _currentUser!.address,
      profileImage: profileImage ?? _currentUser!.profileImage,
      updatedAt: DateTime.now(),
    );

    return _currentUser!;
  }

  /// Get user by ID
  /// 
  /// TODO: Replace with Firebase Firestore
  Future<UserModel?> getUserById(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (_currentUser?.id == userId) {
      return _currentUser;
    }
    
    return null;
  }
}
