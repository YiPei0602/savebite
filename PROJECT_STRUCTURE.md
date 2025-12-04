# SaveBite - Project Structure

## 📁 Directory Organization

```
lib/
├── main.dart                          # App entry point
├── core/                              # Core utilities, shared across app
│   ├── theme/
│   │   ├── app_colors.dart           # Color palette (Jade Green, Orange, etc.)
│   │   ├── app_typography.dart       # Text styles (Poppins font)
│   │   └── app_theme.dart            # Complete theme configuration
│   ├── constants/
│   │   └── app_constants.dart        # App-wide constants
│   ├── widgets/                       # Reusable UI components
│   │   ├── custom_button.dart        # Primary/Secondary/Accent buttons
│   │   ├── custom_text_field.dart    # Styled input fields
│   │   └── food_card.dart            # Food item card component
│   ├── router/
│   │   └── app_router.dart           # Navigation configuration (go_router)
│   └── utils/                         # Utility functions (to be added)
├── features/                          # Feature modules
│   ├── auth/
│   │   └── screens/
│   │       ├── login_screen.dart     # Login page
│   │       └── signup_screen.dart    # Registration with role selection
│   ├── home/
│   │   └── screens/
│   │       └── home_screen.dart      # Main navigation hub
│   ├── marketplace/
│   │   └── screens/
│   │       └── marketplace_screen.dart # Browse surplus food
│   ├── impact/
│   │   └── screens/
│   │       └── impact_dashboard_screen.dart # Impact metrics
│   └── profile/
│       └── screens/
│           └── profile_screen.dart   # User profile & settings
├── models/                            # Data models (to be added)
├── services/                          # API & Firebase services (to be added)
└── providers/                         # State management (to be added)

assets/
├── images/                            # Image assets
├── icons/                             # Icon assets
└── logos/                             # Logo assets
```

---

## 🎨 Design System

### Colors
Located in: `lib/core/theme/app_colors.dart`

| Color | Hex | Usage |
|-------|-----|-------|
| **Primary (Jade Green)** | `#00A86B` | Headers, primary buttons, active states |
| **Accent (Bright Orange)** | `#FF9F1C` | Discount tags, CTAs, price highlights |
| **Background** | `#F8F9FA` | App background |
| **Surface** | `#FFFFFF` | Cards, elevated surfaces |

### Typography
Located in: `lib/core/theme/app_typography.dart`

- **Font Family**: Poppins (Google Fonts)
- **Headings**: H1-H5 with bold/semibold weights
- **Body Text**: Large, Medium, Small variants
- **Specialized**: Button text, prices, impact numbers

### UI Components
Located in: `lib/core/widgets/`

#### CustomButton
```dart
CustomButton(
  text: 'Login',
  onPressed: () {},
  variant: ButtonVariant.primary, // primary, secondary, text, accent
  size: ButtonSize.medium,         // small, medium, large
  isFullWidth: true,
  isLoading: false,
)
```

#### CustomTextField
```dart
CustomTextField(
  label: 'Email',
  hint: 'Enter your email',
  controller: emailController,
  prefixIcon: Icons.email_outlined,
  validator: (value) => value?.isEmpty ? 'Required' : null,
)
```

#### FoodCard
```dart
FoodCard(
  imageUrl: 'https://...',
  title: 'Delicious Food',
  merchantName: 'Restaurant Name',
  originalPrice: 25.00,
  discountedPrice: 12.50,
  discountPercentage: 50,
  category: 'Bakery',
  quantity: 5,
  onTap: () {},
)
```

---

## 🧭 Navigation

Using **go_router** for declarative routing.

### Routes
Located in: `lib/core/router/app_router.dart`

| Route | Name | Screen |
|-------|------|--------|
| `/login` | login | LoginScreen |
| `/signup` | signup | SignupScreen |
| `/home` | home | HomeScreen (with bottom nav) |
| `/marketplace` | marketplace | MarketplaceScreen |
| `/impact` | impact | ImpactDashboardScreen |
| `/profile` | profile | ProfileScreen |

### Navigation Examples
```dart
// Navigate to a route
context.go('/login');

// Navigate with named route
context.goNamed('marketplace');

// Go back
context.pop();
```

---

## 📱 Features Overview

### Module 1: Authentication & User Management
**Status**: ✅ UI Complete | ⏳ Backend Pending

**Screens**:
- `LoginScreen` - Email/password login
- `SignupScreen` - Registration with role selection (Consumer/Merchant/NGO)

**TODO**:
- [ ] Integrate Firebase Authentication
- [ ] Implement password reset
- [ ] Add social login (Google, Apple)

---

### Module 2: Marketplace
**Status**: ✅ UI Complete | ⏳ Backend Pending

**Screens**:
- `MarketplaceScreen` - Browse surplus food items
  - Category filtering
  - Grid layout with FoodCard components
  - Search functionality (placeholder)

**TODO**:
- [ ] Connect to Firestore for real food data
- [ ] Implement search & filters
- [ ] Add food detail screen
- [ ] Implement location-based filtering

---

### Module 3: Impact Dashboard
**Status**: ✅ UI Complete | ⏳ Backend Pending

**Screens**:
- `ImpactDashboardScreen` - Personal impact metrics
  - Meals saved counter
  - CO₂ reduced tracker
  - Money saved calculator
  - Monthly progress goals

**TODO**:
- [ ] Connect to user data from Firestore
- [ ] Implement real-time calculations
- [ ] Add charts/graphs
- [ ] Social sharing features

---

### Module 4: Profile & Settings
**Status**: ✅ UI Complete | ⏳ Backend Pending

**Screens**:
- `ProfileScreen` - User profile & settings
  - Profile information
  - Order history (link)
  - Saved addresses (link)
  - Payment methods (link)
  - Logout

**TODO**:
- [ ] Profile editing
- [ ] Image upload
- [ ] Settings screens
- [ ] Order history implementation

---

## 🔧 Dependencies

### UI & Design
- `google_fonts` - Poppins typography
- `cached_network_image` - Optimized image loading
- `shimmer` - Loading states
- `flutter_svg` - SVG support
- `badges` - Notification badges

### State Management
- `provider` - State management solution

### Navigation
- `go_router` - Declarative routing

### Backend & Services
- `firebase_core` - Firebase initialization
- `firebase_auth` - Authentication
- `cloud_firestore` - Database
- `firebase_storage` - File storage

### Location & Maps
- `google_maps_flutter` - Maps integration
- `geolocator` - Location services
- `geocoding` - Address conversion

### Payment
- `flutter_stripe` - Stripe payment integration

### Networking
- `http` - HTTP requests
- `dio` - Advanced HTTP client

### Storage
- `shared_preferences` - Local key-value storage

### Utilities
- `intl` - Internationalization & formatting
- `uuid` - Unique ID generation
- `url_launcher` - Open URLs/phone/email

---

## 🚀 Getting Started

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Run the App
```bash
# Web
flutter run -d chrome

# macOS
flutter run -d macos

# Android (after accepting licenses)
flutter run -d android

# iOS (requires Xcode 15+)
flutter run -d ios
```

### 3. Hot Reload
Press `r` in terminal or save files in VS Code to hot reload changes.

---

## 📝 Coding Guidelines

### File Naming
- Use `snake_case` for file names
- Suffix with type: `_screen.dart`, `_widget.dart`, `_provider.dart`

### Code Style
- Follow official [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Use `flutter_lints` for code quality
- Add documentation comments for public APIs

### Component Structure
```dart
/// Brief description
/// 
/// Detailed explanation of the component.
class MyWidget extends StatelessWidget {
  // Properties
  final String title;
  
  // Constructor
  const MyWidget({super.key, required this.title});
  
  // Build method
  @override
  Widget build(BuildContext context) {
    return Container();
  }
  
  // Private helper methods
  Widget _buildHelper() {
    return Container();
  }
}
```

### Constants Usage
Always use constants from `AppConstants` and `AppColors`:
```dart
// ✅ Good
padding: const EdgeInsets.all(AppConstants.paddingM),
color: AppColors.primary,

// ❌ Bad
padding: const EdgeInsets.all(16),
color: Color(0xFF00A86B),
```

---

## 🔜 Next Steps

### Immediate (Week 1-2)
1. **Firebase Setup**
   - Create Firebase project
   - Add configuration files
   - Initialize Firebase in app

2. **Authentication Implementation**
   - Connect login/signup to Firebase Auth
   - Implement auth state management
   - Add protected routes

3. **Data Models**
   - Create model classes for User, Food, Order, etc.
   - Add JSON serialization

### Short-term (Week 3-4)
4. **Marketplace Backend**
   - Firestore data structure
   - CRUD operations for food items
   - Real-time updates

5. **Order Flow**
   - Shopping cart
   - Checkout process
   - Stripe integration

### Medium-term (Month 2)
6. **Merchant Features**
   - Merchant dashboard
   - Add/edit food items
   - Sales analytics

7. **NGO Features**
   - Donation tracking
   - Automated donation logic

8. **Advanced Features**
   - Push notifications
   - Location-based search
   - Image upload for food items

---

## 📞 Support

For questions or issues:
1. Check this documentation
2. Review Flutter documentation: https://docs.flutter.dev
3. Check package documentation on pub.dev

---

**Last Updated**: December 4, 2024  
**Version**: 1.0.0  
**Flutter**: 3.22.3  
**Dart**: 3.4.4
