# 📂 SaveBite - Project Structure Guide

A simple guide to understanding the code structure of SaveBite.

---

## 🎯 Quick Overview

Think of your app like a restaurant:
- **Screens** = Different rooms (dining room, kitchen, office)
- **Models** = Menu items (what food you serve)
- **Providers** = Waiters (they remember what customers ordered)
- **Services** = Kitchen staff (they prepare the food/do the work)
- **Core** = Restaurant rules & design (colors, fonts, how things look)

---

## 📁 New Feature-Based Structure

```
lib/
├── main.dart                    # App entry point
├── core/                        # Shared across ALL features
│   ├── theme/                   # Colors, fonts, theme
│   ├── constants/               # App-wide constants
│   ├── widgets/                 # Shared reusable widgets
│   └── router/                  # Navigation
│
├── features/                    # All features organized here
│   │
│   ├── auth/                    # Module 1: Authentication
│   │   ├── screens/
│   │   │   ├── login_screen.dart
│   │   │   └── signup_screen.dart
│   │   ├── models/
│   │   │   └── user_model.dart
│   │   ├── providers/
│   │   │   └── auth_provider.dart
│   │   └── services/
│   │       └── auth_service.dart
│   │
│   ├── landing/                 # Landing & Role Selection
│   │   └── screens/
│   │       ├── landing_page_screen.dart
│   │       └── role_based_login_screen.dart
│   │
│   ├── marketplace/             # Module 2: Food Discovery
│   │   ├── screens/
│   │   │   ├── marketplace_screen.dart
│   │   │   ├── merchant_details_screen.dart
│   │   │   └── category_listing_screen.dart
│   │   ├── models/
│   │   │   ├── food_item_model.dart
│   │   │   └── merchant_model.dart
│   │   ├── providers/
│   │   │   ├── food_provider.dart
│   │   │   └── merchant_provider.dart
│   │   └── services/
│   │       ├── food_service.dart
│   │       └── merchant_service.dart
│   │
│   ├── merchant/                # Module 2: Merchant Management
│   │   └── screens/
│   │       ├── merchant_dashboard_screen.dart
│   │       ├── add_surplus_screen.dart
│   │       └── merchant_orders_screen.dart
│   │
│   ├── cart/                    # Module 3: Shopping Cart
│   │   ├── screens/
│   │   │   └── cart_screen.dart
│   │   ├── models/
│   │   │   └── cart_item_model.dart
│   │   ├── providers/
│   │   │   └── cart_provider.dart
│   │   └── services/
│   │
│   ├── checkout/                # Module 3: Checkout
│   │   └── screens/
│   │       └── checkout_screen.dart
│   │
│   ├── orders/                  # Module 3 & 4: Orders & Tracking
│   │   ├── screens/
│   │   │   ├── order_history_screen.dart
│   │   │   ├── order_tracking_screen.dart
│   │   │   └── track_order_screen.dart
│   │   ├── models/
│   │   │   └── order_model.dart
│   │   ├── providers/
│   │   │   └── order_provider.dart
│   │   └── services/
│   │       └── order_service.dart
│   │
│   ├── payment/                 # Module 3: Payment
│   │   └── screens/
│   │       └── payment_methods_screen.dart
│   │
│   ├── notifications/           # Module 3: Notifications
│   │   └── screens/
│   │       └── notifications_screen.dart
│   │
│   ├── profile/                 # Module 1: Profile
│   │   └── screens/
│   │       ├── profile_screen.dart
│   │       └── edit_profile_screen.dart
│   │
│   ├── impact/                  # Module 1: Impact Dashboard
│   │   └── screens/
│   │       └── impact_dashboard_screen.dart
│   │
│   ├── donation/                # Module 5: Donations
│   │   ├── screens/
│   │   │   └── donation_prompt_screen.dart
│   │   ├── models/
│   │   │   └── donation_model.dart
│   │   ├── providers/
│   │   │   └── donation_provider.dart
│   │   └── services/
│   │       └── donation_service.dart
│   │
│   └── home/                    # Main Navigation Wrapper
│       └── screens/
│           └── home_screen.dart
│
└── shared/                      # Shared utilities
    └── utils/
        └── price_utils.dart
```

---

## 🎯 Key Principles

### 1. Feature-Based Organization
**Each feature is self-contained:**
- All screens, models, providers, and services for a feature are in one folder
- Easy to find: "Where's cart code?" → `features/cart/`
- Easy to understand: Everything related to cart is together

### 2. Clear Separation
- **`core/`** = Shared across ALL features (theme, router, widgets)
- **`features/`** = Feature-specific code
- **`shared/`** = Utilities used by multiple features

### 3. Consistent Structure
Every feature follows the same pattern:
```
feature_name/
├── screens/      # UI screens
├── models/      # Data structures (if needed)
├── providers/   # State management (if needed)
└── services/    # Backend calls (if needed)
```

---

## 📊 Feature Mapping to Modules

| Feature Folder | Module | Purpose |
|---------------|--------|---------|
| `auth/` | Module 1 | Authentication & login |
| `profile/` | Module 1 | User profile management |
| `impact/` | Module 1 | Impact dashboard |
| `marketplace/` | Module 2 | Food discovery & browsing |
| `merchant/` | Module 2 | Merchant management |
| `cart/` | Module 3 | Shopping cart |
| `checkout/` | Module 3 | Checkout process |
| `orders/` | Module 3 & 4 | Orders & tracking |
| `payment/` | Module 3 | Payment methods |
| `notifications/` | Module 3 | Notifications |
| `donation/` | Module 5 | Donation coordination |

---

## 🔄 How They Work Together

### Example: User Adds Food to Cart

1. **Screen** (`features/marketplace/screens/merchant_details_screen.dart`)
   - User taps "Add to Cart" button
   - Screen calls Cart Provider

2. **Provider** (`features/cart/providers/cart_provider.dart`)
   - Receives the food item (using `FoodItemModel`)
   - Adds it to cart list (using `CartItemModel`)
   - Notifies all screens "cart changed!"

3. **Model** (`features/marketplace/models/food_item_model.dart`)
   - Defines what a food item looks like
   - Provider uses this structure

4. **Screen** (`features/cart/screens/cart_screen.dart`)
   - Listens to Cart Provider
   - Shows updated cart automatically

---

## 📝 Quick Reference Table

| Folder/File | What It Does | Real Life Example |
|------------|--------------|-------------------|
| `main.dart` | Starts the app | Power button |
| `core/` | Shared utilities | Restaurant rules |
| `features/*/screens/` | Feature pages | Different rooms |
| `features/*/models/` | Data templates | Form templates |
| `features/*/providers/` | State managers | Notebook/memory |
| `features/*/services/` | Backend workers | Waiter/worker |
| `shared/utils/` | Helper functions | Calculator |

---

## 🎯 Summary in One Sentence Each

- **main.dart** → Starts everything
- **core/** → Shared design system (colors, fonts, widgets, router)
- **features/** → All features organized by functionality
- **shared/** → Helper utilities used across features

---

## 💡 Benefits of This Structure

### ✅ Clear Organization
- Easy to find code: "Cart code? → `features/cart/`"
- No confusion about where files belong

### ✅ Scalable
- Add new features easily: just create new folder
- Each feature is independent

### ✅ Maintainable
- Change cart feature? Only touch `features/cart/`
- No scattered files across multiple folders

### ✅ Team-Friendly
- Different developers can work on different features
- Clear boundaries between features

---

## 🗺️ Module Mapping

Each module uses specific feature folders:

- **Module 1 (User & Impact)**: `auth/`, `profile/`, `impact/`, `admin/`
- **Module 2 (Food Management)**: `marketplace/`, `merchant/`
- **Module 3 (Order & Payment)**: `cart/`, `checkout/`, `orders/`, `payment/`, `notifications/`
- **Module 4 (Delivery & Pickup)**: `orders/` (tracking screens)
- **Module 5 (Donations)**: `donation/`

See [MODULES.md](MODULES.md) for detailed module information.

---

**That's it! Simple and clear! 😊**
