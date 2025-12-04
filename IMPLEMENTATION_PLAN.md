# SaveBite - Complete Module Implementation Plan

## ✅ Font Update: COMPLETE
- Switched from Poppins to **Inter** (matching Grab Food)

---

## 📋 Module Implementation Roadmap

### MODULE 1: User Profile & Personalized Impact Dashboard

#### 1.1 Authentication Screens ✅ TO IMPLEMENT
**Files to create:**
- `lib/features/auth/screens/login_screen.dart`
- `lib/features/auth/screens/register_screen.dart`
- `lib/features/auth/screens/role_selection_screen.dart`
- `lib/features/auth/providers/auth_provider.dart`

**Features:**
- Email/password login with validation
- Registration with role selection (Consumer/Merchant/Admin)
- Password visibility toggle
- "Forgot Password" link
- Social login buttons (Google, Facebook) - UI only
- Form validation and error messages
- Remember me checkbox
- Navigate to role selection after registration

#### 1.2 Profile Edit Screen ✅ TO IMPLEMENT
**Files to create:**
- `lib/features/profile/screens/edit_profile_screen.dart`

**Features:**
- Edit name, email, phone, address
- Upload profile picture (image picker)
- Change password section
- Save/Cancel buttons
- Form validation
- Success/error feedback

#### 1.3 Admin Dashboard ✅ TO IMPLEMENT
**Files to create:**
- `lib/features/admin/screens/admin_dashboard_screen.dart`
- `lib/features/admin/screens/user_management_screen.dart`
- `lib/features/admin/screens/system_reports_screen.dart`

**Features:**
- Overview stats (users, orders, donations)
- User management (view, suspend, delete)
- System activity logs
- Performance reports (charts/graphs)
- Export data functionality

---

### MODULE 2: Surplus Food Management & Discovery

#### 2.1 Merchant Surplus Management ✅ TO IMPLEMENT
**Files to create:**
- `lib/features/merchant/screens/merchant_dashboard_screen.dart`
- `lib/features/merchant/screens/add_surplus_screen.dart`
- `lib/features/merchant/screens/edit_surplus_screen.dart`
- `lib/features/merchant/screens/my_listings_screen.dart`

**Features:**
- View all merchant's surplus listings
- Add new surplus item (name, description, image, quantity, price, discount %)
- Edit existing listings
- Delete/deactivate listings
- Dynamic discount pricing slider
- Category selection
- Dietary tags (Halal, Vegetarian, Vegan, etc.)
- Set pickup time windows
- Real-time inventory management

#### 2.2 Enhanced Consumer Discovery ✅ TO IMPLEMENT
**Files to update:**
- `lib/screens/home_screen.dart` (add dietary filters)

**Features:**
- Dietary preference filters (Halal, Vegetarian, Vegan, Gluten-Free)
- Sort by: Distance, Price, Discount, Rating
- Save favorite merchants
- Real-time availability badges

#### 2.3 Real-Time Updates ✅ TO IMPLEMENT
**Files to create:**
- `lib/core/services/realtime_service.dart`
- `lib/core/providers/surplus_provider.dart`

**Features:**
- Stream-based updates for availability
- Live discount changes
- Sold out notifications
- New listings alerts

---

### MODULE 3: Order & Payment Management

#### 3.1 Payment Gateway Integration ✅ TO IMPLEMENT
**Files to create:**
- `lib/core/services/payment_service.dart`
- `lib/features/payment/screens/payment_methods_screen.dart`
- `lib/features/payment/screens/add_payment_method_screen.dart`

**Features:**
- Stripe integration (re-enable plugin)
- Save payment methods
- Secure card tokenization
- Payment confirmation flow
- Receipt generation

#### 3.2 Notification System ✅ TO IMPLEMENT
**Files to create:**
- `lib/core/services/notification_service.dart`
- `lib/features/notifications/screens/notifications_screen.dart`
- `lib/core/models/notification_model.dart`

**Features:**
- In-app notifications list
- Push notifications (FCM) - setup only
- Order status notifications
- Payment confirmations
- Merchant order alerts
- Notification preferences

#### 3.3 Merchant Order Management ✅ TO IMPLEMENT
**Files to create:**
- `lib/features/merchant/screens/merchant_orders_screen.dart`
- `lib/features/merchant/screens/order_details_merchant_screen.dart`
- `lib/features/merchant/screens/daily_summary_screen.dart`

**Features:**
- View incoming orders
- Accept/reject orders
- Mark as ready for pickup
- Daily sales summary
- Order history
- Revenue analytics

---

### MODULE 4: Delivery & Pickup Scheduling

#### 4.1 Live Tracking Enhancement ✅ TO IMPLEMENT
**Files to update:**
- `lib/screens/order_tracking_screen.dart`

**Files to create:**
- `lib/core/services/location_service.dart`

**Features:**
- Real geolocation using geolocator
- Google Maps integration (replace placeholder)
- Live route updates
- ETA calculation
- Driver location (for delivery)
- Geofencing for pickup arrival

#### 4.2 Delivery Notifications ✅ TO IMPLEMENT
**Features:**
- "Order is ready" notification
- "Pickup window closing" alert
- Delivery status updates
- SMS notifications (Twilio) - setup only

---

### MODULE 5: Smart Donation Coordination

#### 5.1 Merchant Donation Screens ✅ TO IMPLEMENT
**Files to create:**
- `lib/features/donation/screens/donation_prompt_screen.dart`
- `lib/features/donation/screens/donation_history_screen.dart`
- `lib/core/services/donation_service.dart`

**Features:**
- Automated donation prompt (scheduled)
- Accept/reject donation dialog
- Select NGO from list
- Donation confirmation
- Donation history for merchant
- Impact tracking (meals donated)

#### 5.2 Admin Donation Monitoring ✅ TO IMPLEMENT
**Files to create:**
- `lib/features/admin/screens/donation_monitoring_screen.dart`
- `lib/features/admin/screens/ngo_management_screen.dart`

**Features:**
- View all donations
- Track NGO deliveries
- Donation analytics
- NGO management (add/edit/remove)
- Donation reports
- Export donation data

---

## 🗂️ Additional Required Files

### Models
- `lib/core/models/user_model.dart`
- `lib/core/models/surplus_item_model.dart`
- `lib/core/models/order_model.dart`
- `lib/core/models/donation_model.dart`
- `lib/core/models/ngo_model.dart`

### Providers (State Management)
- `lib/core/providers/user_provider.dart`
- `lib/core/providers/cart_provider.dart`
- `lib/core/providers/order_provider.dart`

### Services
- `lib/core/services/api_service.dart` (backend API calls)
- `lib/core/services/storage_service.dart` (local storage)
- `lib/core/services/image_service.dart` (image upload)

---

## 📊 Implementation Priority

### Phase 1: Authentication & Roles (CRITICAL)
1. Login Screen
2. Register Screen
3. Role Selection
4. Auth Provider

### Phase 2: Merchant Tools (HIGH)
5. Merchant Dashboard
6. Add/Edit Surplus
7. Merchant Orders
8. Daily Summary

### Phase 3: Enhanced Consumer Experience (HIGH)
9. Profile Edit
10. Payment Methods
11. Notifications
12. Dietary Filters

### Phase 4: Real-Time & Tracking (MEDIUM)
13. Real-time Service
14. Live Tracking with Maps
15. Location Service

### Phase 5: Donations & Admin (MEDIUM)
16. Donation Prompt
17. Donation History
18. Admin Dashboard
19. Donation Monitoring

---

## 🚀 Next Steps

1. **Create folder structure** for new features
2. **Implement Phase 1** (Auth screens)
3. **Update routing** to include new screens
4. **Add Provider setup** in main.dart
5. **Implement remaining phases** sequentially
6. **Test complete user flows**
7. **Document API requirements** for backend team

---

## 📝 Notes

- All screens will use **Inter font** (already updated)
- Design system colors remain: #00A86B (primary), #FF9F1C (accent)
- Dummy data for now; backend integration points marked with `// TODO: Backend`
- Firebase/Stripe temporarily disabled for iOS build; will re-enable after screens are complete
- Focus on UI/UX completeness first, then add backend hooks

---

**Estimated Total: 25+ new screens, 15+ services/providers, 10+ models**

This is a comprehensive implementation that will make SaveBite production-ready!
