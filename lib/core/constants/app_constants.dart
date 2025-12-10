/// SaveBite App Constants
/// 
/// This file contains all constant values used throughout the app.
class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();

  // ============================================================================
  // APP INFO
  // ============================================================================
  static const String appName = 'SaveBite';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Fresh Food. Half Price. Zero Waste.';

  // ============================================================================
  // SPACING & SIZING
  // ============================================================================
  
  // Padding & Margins
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;

  // Border Radius
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusCircle = 999.0;

  // Icon Sizes
  static const double iconXS = 16.0;
  static const double iconS = 20.0;
  static const double iconM = 24.0;
  static const double iconL = 32.0;
  static const double iconXL = 48.0;

  // Image Sizes
  static const double imageThumbS = 60.0;
  static const double imageThumbM = 80.0;
  static const double imageThumbL = 120.0;
  static const double imageCardHeight = 200.0;
  static const double imageHeroHeight = 300.0;

  // Button Heights
  static const double buttonHeightS = 36.0;
  static const double buttonHeightM = 48.0;
  static const double buttonHeightL = 56.0;

  // ============================================================================
  // ANIMATION DURATIONS
  // ============================================================================
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // ============================================================================
  // USER ROLES
  // ============================================================================
  static const String roleMerchant = 'merchant';
  static const String roleConsumer = 'consumer';
  static const String roleNGO = 'ngo';

  // ============================================================================
  // FOOD CATEGORIES
  // ============================================================================
  static const List<String> foodCategories = [
    'Bakery',
    'Meats',
    'Vegetables',
    'Dairy',
    'Prepared Meals',
    'Beverages',
    'Snacks',
    'Other',
  ];

  // ============================================================================
  // ORDER STATUS
  // ============================================================================
  static const String orderPending = 'pending';
  static const String orderConfirmed = 'confirmed';
  static const String orderReady = 'ready';
  static const String orderCompleted = 'completed';
  static const String orderCancelled = 'cancelled';

  // ============================================================================
  // PAYMENT STATUS
  // ============================================================================
  static const String paymentPending = 'pending';
  static const String paymentSuccess = 'success';
  static const String paymentFailed = 'failed';

  // ============================================================================
  // VALIDATION
  // ============================================================================
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 50;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  static const int maxDescriptionLength = 500;

  // ============================================================================
  // PAGINATION
  // ============================================================================
  static const int itemsPerPage = 20;
  static const int maxSearchResults = 50;

  // ============================================================================
  // LOCATION
  // ============================================================================
  static const double defaultLatitude = 3.1390; // Kuala Lumpur
  static const double defaultLongitude = 101.6869;
  static const double defaultSearchRadius = 10.0; // km
  static const double maxSearchRadius = 50.0; // km

  // ============================================================================
  // DISCOUNT
  // ============================================================================
  static const double minDiscountPercentage = 10.0;
  static const double maxDiscountPercentage = 90.0;

  // ============================================================================
  // IMPACT METRICS
  // ============================================================================
  static const double co2PerMeal = 2.5; // kg CO2 saved per meal
  static const String currencySymbol = 'RM'; // Malaysian Ringgit

  // ============================================================================
  // TIME FORMATS
  // ============================================================================
  static const String dateFormat = 'dd MMM yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd MMM yyyy, HH:mm';

  // ============================================================================
  // ERROR MESSAGES
  // ============================================================================
  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String errorNetwork = 'No internet connection. Please check your network.';
  static const String errorAuth = 'Authentication failed. Please login again.';
  static const String errorPermission = 'Permission denied. Please grant required permissions.';
  
  // ============================================================================
  // SUCCESS MESSAGES
  // ============================================================================
  static const String successLogin = 'Welcome back!';
  static const String successSignup = 'Account created successfully!';
  static const String successOrderPlaced = 'Order placed successfully!';
  static const String successProfileUpdated = 'Profile updated successfully!';
}
