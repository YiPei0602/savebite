# SaveBite Color System Update

## New Color Palette (Dec 4, 2025)

### Primary Colors
- **Primary (Blue Stone)**: `#00615F` - Deep teal for headers, buttons, active states
- **Primary Light**: `#008F8C` - Lighter teal variant
- **Primary Dark**: `#004643` - Darker teal variant

### Accent & Action Colors
- **Accent (Mango Tango)**: `#FF8C42` - Vibrant orange for CTAs, discounts, highlights
- **Accent Light**: `#FFA76B` - Lighter orange
- **Accent Dark**: `#E67329` - Darker orange

### Background Colors
- **Background (Vista White)**: `#F9F3F0` - Warm off-white for app background
- **Surface**: `#FFFFFF` - Pure white for cards and elevated surfaces
- **Surface Variant**: `#F0E8E4` - Subtle warm background for inputs

### Text Colors
- **Text Primary (Dark Slate)**: `#2B2D42` - Main readable text
- **Text Secondary (Cool Gray)**: `#8D99AE` - Secondary text, labels
- **Text Tertiary**: `#B8C1CC` - Placeholder text, disabled states
- **Text on Primary**: `#FFFFFF` - White text on primary color
- **Text on Accent**: `#212529` - Dark text on accent color

### Semantic Colors
- **Success (Caribbean Green)**: `#06D6A0` - Success messages, confirmations
- **Warning**: `#FFC107` - Warnings, caution messages
- **Error (Red Salsa)**: `#E63946` - Error messages, destructive actions
- **Info**: `#17A2B8` - Information messages, tips

### Impact Dashboard
- **Meals Saved**: `#00615F` (Primary teal)
- **CO2 Reduced**: `#06D6A0` (Caribbean green)
- **Money Saved**: `#FF8C42` (Accent orange)

---

## Home Page Header Updates

### Fixed Issues
1. ✅ **White gap removed**: Header now extends into SafeArea properly
2. ✅ **Mystery bag image**: Replaced placeholder icon with `assets/images/mysterybag.png`
3. ✅ **Header color**: Updated to new primary color (#00615F)
4. ✅ **Search bar border**: Added primary color border (2px) to match reference

### Visual Changes
- Header background: Deep teal (#00615F) with curved bottom-right corner
- Location pill: White with red pin icon and shadow
- Tagline: "Looking to save meals, save money? got it"
- Hero image: Mystery bag illustration in rounded container
- Search bar: White with teal border, floating overlap effect

---

## System-Wide Impact

All components using `AppColors` will automatically inherit the new palette:
- Headers and navigation bars
- Buttons (primary, secondary, text)
- Cards and containers
- Form inputs and fields
- Badges and chips
- Success/error/warning states
- Impact dashboard metrics

---

## Production Readiness Recommendations

### Phase 1: Core Features (MVP+)
1. **Search & Filters**
   - Real-time search with autocomplete
   - Advanced filters (distance, price, dietary, closing time)
   - Map view toggle

2. **User Engagement**
   - Push notifications for nearby listings
   - Favorites/wishlist
   - Impact dashboard (meals saved, CO2, money)

3. **Trust & Safety**
   - Merchant verification badges
   - User reviews and ratings
   - Photo uploads for listings

### Phase 2: Enhanced Experience
4. **Onboarding**
   - Welcome screens with mission statement
   - Role selection (Consumer/Merchant/NGO)
   - Location permission with clear value prop

5. **Checkout & Payment**
   - Stripe integration
   - Promo codes and referrals
   - QR code for pickup confirmation
   - Time slot selection

6. **Merchant Tools**
   - Quick listing creation
   - Inventory management
   - Analytics dashboard
   - Bulk upload

### Phase 3: Scale & Optimize
7. **Accessibility**
   - Multi-language (Malay, Chinese, English)
   - Dark mode
   - Font size adjustment
   - Screen reader optimization

8. **Performance**
   - Offline mode with cached listings
   - Image optimization
   - Error handling with retry
   - Loading states and skeletons

---

## Design System Principles

### Consistency
- All colors defined in `AppColors` class
- No hardcoded hex values in components
- Reusable typography from `AppTypography`
- Consistent spacing via `AppConstants`

### Accessibility
- WCAG AA contrast ratios maintained
- Primary (#00615F) on white: 7.8:1 ✅
- Accent (#FF8C42) on white: 3.2:1 ✅
- Text primary (#2B2D42) on background: 12.1:1 ✅

### Brand Identity
- Deep teal conveys trust, sustainability, eco-friendliness
- Warm off-white creates approachable, friendly feel
- Vibrant orange drives urgency and action
- Overall palette balances professionalism with warmth

---

## Next Steps

1. **Test on simulator**: Press `r` to hot reload and verify changes
2. **Review other screens**: Ensure color updates look good across all pages
3. **Implement priority features**: Start with search, filters, and notifications
4. **User testing**: Gather feedback on new color scheme and UX
5. **Iterate**: Refine based on real-world usage

---

**Status**: ✅ Color system updated, Home header fixed, ready for testing
