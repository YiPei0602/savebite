# 📚 SaveBite - Module Documentation

This document describes the five core modules that make up the SaveBite platform.

---

## Module 1: User Profile & Personalized Impact Dashboard

### Overview
Manages user authentication, profiles, and tracks sustainability impact for both merchants and consumers.

### Features

#### Authentication & Access
- ✅ **Role-based Registration**: Merchants and consumers can register new accounts
- ✅ **Role-based Login**: Login via role-based access (Consumer/Merchant/Admin)
- ✅ **Role Selection Screen**: Choose role after login

#### Profile Management
- ✅ **View Profile**: Display user information
- ✅ **Edit Profile**: Update profile information (name, email, phone, address)
- ✅ **Profile Picture**: Upload and manage profile picture

#### Impact Dashboard
- ✅ **Personalized Impact Tracking**: Visual dashboard showing:
  - Meals saved
  - CO₂ reduced (in kg)
  - Money saved (in RM)
- ✅ **Impact Metrics**: Real-time calculation of sustainability contributions
- ✅ **Visual Display**: Clean, card-based layout with icons and metrics

#### Admin Features
- ⚠️ **Note**: Admin interface is managed through a separate web portal, not included in mobile app

### Screens
- `lib/features/auth/screens/login_screen.dart`
- `lib/features/auth/screens/signup_screen.dart`
- `lib/features/landing/screens/role_based_login_screen.dart`
- `lib/features/profile/screens/profile_screen.dart`
- `lib/features/profile/screens/edit_profile_screen.dart`
- `lib/features/impact/screens/impact_dashboard_screen.dart`

### Models
- `lib/models/user_model.dart`

### Providers
- `lib/providers/auth_provider.dart`

### Services
- `lib/services/auth_service.dart`

---

## Module 2: Surplus Food Management & Discovery

### Overview
Enables merchants to manage surplus food listings and allows consumers to discover available food items.

### Features

#### Merchant Management
- ✅ **Add Surplus Items**: Create new surplus food listings
- ✅ **Update Listings**: Edit existing surplus food items
- ✅ **Remove Listings**: Delete surplus food items
- ✅ **Dynamic Pricing**: Apply dynamic discount pricing (10% - 90%)
- ✅ **Merchant Dashboard**: Overview of all listings with stats
- ✅ **Manage Listings**: View, edit, and delete items from dashboard

#### Consumer Discovery
- ✅ **Browse Food Items**: View available surplus food
- ✅ **Search**: Search for food items by name
- ✅ **Category Filtering**: Filter by food categories (Food, Beverages, Bakery, etc.)
- ✅ **Dietary Filters**: Filter by dietary preferences (Halal, Vegetarian, etc.)
- ✅ **Location Filtering**: Filter by location (planned)
- ✅ **Merchant Details**: View merchant information and all their items

#### Real-time Updates
- ⏳ **Availability Updates**: Real-time updates on item availability (planned)
- ⏳ **Discount Updates**: Real-time discount changes (planned)
- ⏳ **New Item Notifications**: Notify consumers of new items (planned)

### Screens
- `lib/screens/home_screen.dart` - Main discovery feed
- `lib/screens/merchant_details_screen.dart` - Merchant profile
- `lib/screens/category_listing_screen.dart` - Category view
- `lib/features/merchant/screens/merchant_dashboard_screen.dart`
- `lib/features/merchant/screens/add_surplus_screen.dart`
- `lib/features/marketplace/screens/marketplace_screen.dart`

### Models
- `lib/models/food_item_model.dart`
- `lib/models/merchant_model.dart`

### Providers
- `lib/providers/food_provider.dart`
- `lib/providers/merchant_provider.dart`

### Services
- `lib/services/food_service.dart`
- `lib/services/merchant_service.dart`

---

## Module 3: Order & Payment Management

### Overview
Handles the complete order lifecycle from cart to payment, including notifications for both consumers and merchants.

### Features

#### Shopping Cart
- ✅ **Add to Cart**: Add items to shopping cart
- ✅ **View Cart**: Display all cart items with quantities
- ✅ **Update Quantities**: Increase/decrease item quantities
- ✅ **Remove Items**: Remove items from cart
- ✅ **Clear Cart**: Clear all items with confirmation
- ✅ **Price Calculation**: Show subtotal, savings, and total

#### Checkout & Payment
- ✅ **Checkout Screen**: Review order before payment
- ✅ **Order Summary**: Display items, prices, and totals
- ✅ **Payment Methods**: Manage saved payment methods
- ✅ **Secure Checkout**: Proceed with payment (UI ready)
- ⏳ **Payment Gateway**: Stripe integration (planned)
- ⏳ **Payment Processing**: Secure online payment processing (planned)

#### Notifications
- ✅ **Order Notifications**: Notify consumers on:
  - Successful payment
  - Order confirmation
  - Order cancellation
- ✅ **Merchant Notifications**: Notify merchants on:
  - New orders
  - Cancelled orders
- ✅ **Notification Screen**: View all notifications
- ✅ **Notification Types**: Color-coded by type (order, promo, impact, payment)

#### Order History
- ✅ **Consumer Order History**: View past orders
- ✅ **Order Details**: View individual order information
- ✅ **Order Status**: Track order status in history

#### Merchant Order Management
- ✅ **Merchant Orders Screen**: View all orders
- ✅ **Order Tabs**: New Orders, Active Orders, Completed Orders
- ✅ **Accept/Reject Orders**: Accept or reject new orders
- ✅ **Mark Ready**: Mark orders as ready for pickup
- ✅ **Daily Summary**: View daily order summaries (planned)

### Screens
- `lib/screens/cart_screen.dart`
- `lib/screens/checkout_screen.dart`
- `lib/screens/order_history_screen.dart`
- `lib/features/payment/screens/payment_methods_screen.dart`
- `lib/features/notifications/screens/notifications_screen.dart`
- `lib/features/merchant/screens/merchant_orders_screen.dart`

### Models
- `lib/models/cart_item_model.dart`
- `lib/models/order_model.dart`

### Providers
- `lib/providers/cart_provider.dart`
- `lib/providers/order_provider.dart`

### Services
- `lib/services/order_service.dart`

---

## Module 4: Delivery & Pickup Scheduling

### Overview
Manages order fulfillment through delivery or self-pickup options with real-time tracking.

### Features

#### Order Fulfillment Options
- ✅ **Delivery Option**: Choose delivery (UI ready)
- ✅ **Self-Pickup Option**: Choose self-pickup (UI ready)
- ⏳ **Delivery Scheduling**: Schedule delivery time (planned)
- ⏳ **Pickup Scheduling**: Schedule pickup time (planned)

#### Order Tracking
- ✅ **Live Order Tracking**: Real-time order status updates
- ✅ **Status Display**: Show current order status
- ✅ **Order Progress**: Visual progress indicator
- ✅ **Order Details**: View order information during tracking
- ⏳ **Live Location**: Real-time location tracking (planned)
- ⏳ **ETA Calculation**: Estimated time of arrival (planned)

#### Notifications
- ✅ **Pickup Updates**: Notify consumers of pickup updates
- ✅ **Delivery Updates**: Notify consumers of delivery updates
- ✅ **Status Changes**: Notify on order status changes

### Screens
- `lib/screens/order_tracking_screen.dart`
- `lib/screens/track_order_screen.dart`

### Models
- `lib/models/order_model.dart` (includes delivery/pickup info)

### Providers
- `lib/providers/order_provider.dart`

### Services
- `lib/services/order_service.dart`

---

## Module 5: Smart Donation Coordination

### Overview
Automates the donation process for unsold surplus food, connecting merchants with NGOs.

### Features

#### Automated Donation System
- ✅ **Donation Prompt**: Automated reminder system before closing hours
- ✅ **Prompt Screen**: Display unsold items with donation prompt
- ✅ **Accept/Reject**: Merchant can accept or reject donation prompt
- ✅ **Unsold Items Display**: Show items available for donation
- ✅ **Total Value**: Display total value of items to donate

#### NGO Selection
- ✅ **NGO List**: Display available NGOs
- ✅ **NGO Selection**: Select NGO to receive donation
- ✅ **NGO Information**: View NGO details
- ⏳ **NGO Matching**: Auto-match based on location/needs (planned)

#### Impact Tracking
- ✅ **Impact Preview**: Show impact of donation:
  - Meals donated
  - CO₂ saved
  - People helped
- ✅ **Donation Confirmation**: Confirm donation action

#### Admin Monitoring
- ⚠️ **Note**: Admin monitoring is handled through a separate web portal, not included in mobile app

### Screens
- `lib/features/donation/screens/donation_prompt_screen.dart`

### Models
- `lib/models/donation_model.dart`

### Providers
- `lib/providers/donation_provider.dart`

### Services
- `lib/services/donation_service.dart`

---

## Module Integration

All five modules work together seamlessly:

1. **Module 1** provides user authentication and profiles
2. **Module 2** enables food discovery and management
3. **Module 3** handles orders and payments
4. **Module 4** manages fulfillment and tracking
5. **Module 5** coordinates donations for unsold items

### Example Flow: Consumer Order
```
Module 1 (Login) 
  → Module 2 (Browse & Add to Cart)
    → Module 3 (Checkout & Payment)
      → Module 4 (Track Order)
```

### Example Flow: Merchant Donation
```
Module 1 (Merchant Login)
  → Module 2 (Manage Listings)
    → Module 5 (Donation Prompt)
      → Module 1 (Impact Dashboard Update)
```

---

## Implementation Status

### ✅ Completed
- All UI screens for all 5 modules
- Navigation and routing
- State management (local)
- Form validation
- Basic data models

### ⏳ In Progress / Planned
- Backend integration (Firebase)
- Real-time updates
- Payment gateway integration
- Location services
- Push notifications
- Advanced analytics

---

## Next Steps

1. **Backend Integration**: Connect to Firebase for real data
2. **Payment Integration**: Implement Stripe payment processing
3. **Location Services**: Add Google Maps and geolocation
4. **Real-time Updates**: Implement live data synchronization
5. **Notifications**: Set up push notifications (FCM)
6. **Testing**: Comprehensive testing of all modules
7. **Deployment**: Prepare for production deployment

