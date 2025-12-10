# Design Document: Landing Page & Role-Based Authentication

## Overview

This design document outlines the implementation of a welcoming landing page and role-based authentication flow for the SaveBite mobile app. The landing page serves as the initial brand touchpoint, while the role-based login screen enables users to select between consumer ("I want to buy") and merchant ("I want to sell") authentication paths. The design emphasizes visual clarity, brand consistency, and intuitive user navigation using SaveBite's color palette (deep teal #00615F, off-white #F9F3F0/#F6F6F6, with accent colors for promotions).

## Architecture

The authentication flow follows a sequential navigation pattern:

```
App Launch
    ↓
Landing Page (Splash Screen)
    ↓ (Auto-navigate or tap)
Role-Based Login Screen
    ↓
    ├─→ "I want to buy" → Consumer Auth Flow
    └─→ "I want to sell" → Merchant Auth Flow
```

**Key Components:**
- Landing Page Screen: Displays brand identity
- Role-Based Login Screen: Presents role selection options
- Navigation Router: Manages transitions between screens and auth flows
- Auth Service: Handles role-based routing logic

## Components and Interfaces

### 1. Landing Page Screen (`landing_page_screen.dart`)

**Purpose**: Display SaveBite brand and logo on app launch

**UI Elements**:
- Full-screen container with deep teal background (#00615F)
- Centered SaveBite logo (flame with spoon/fork icon)
- "SaveBite" text label in off-white below logo
- Optional: Subtle animation or fade-in effect

**Properties**:
- Background color: #00615F (deep teal)
- Logo size: Responsive (approximately 120-150dp)
- Text color: #F9F3F0 or #F6F6F6 (off-white)
- Font: Bold, large (48sp+)
- Auto-navigation delay: 2-3 seconds

**Behavior**:
- Displays on first app launch
- Auto-navigates to role-based login after delay
- Allows manual navigation on tap

### 2. Role-Based Login Screen (`role_based_login_screen.dart`)

**Purpose**: Enable users to select their role (Consumer or Merchant)

**UI Elements**:
- Background: meals.png image with semi-transparent overlay (40-50% opacity)
- Two primary action buttons:
  - "I want to buy" (Consumer role)
  - "I want to sell" (Merchant role)
- Optional: Tagline or description for each role
- Optional: Back button to return to landing page

**Button Styling**:
- Background: Deep teal (#00615F) or outlined style
- Text color: Off-white (#F9F3F0 or #F6F6F6)
- Minimum height: 48dp (touch-friendly)
- Padding: 16dp horizontal, 12dp vertical
- Border radius: 8-12dp
- Font size: 16-18sp (readable on mobile)

**Layout**:
- Buttons positioned in lower half of screen
- Vertical spacing: 16dp between buttons
- Horizontal margins: 16dp from screen edges
- Responsive to screen orientation changes

**Behavior**:
- "I want to buy" → Routes to consumer login/signup
- "I want to sell" → Routes to merchant login/signup
- No admin option displayed

### 3. Navigation Router Updates (`app_router.dart`)

**Routes to Add/Modify**:
- `/landing` → Landing Page Screen
- `/role-login` → Role-Based Login Screen
- `/consumer-auth` → Consumer authentication flow
- `/merchant-auth` → Merchant authentication flow

**Route Guards**:
- Redirect unauthenticated users to landing page
- Prevent admin role access on mobile app
- Maintain role-specific navigation paths

## Data Models

No new data models required. Existing authentication models will be reused:
- `UserModel`: Contains user role information
- `AuthService`: Manages role-based routing

**Role Enum Update**:
```dart
enum UserRole {
  consumer,
  merchant,
  // admin removed from mobile app
}
```

## Correctness Properties

A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.

### Property 1: Landing Page Auto-Navigation
*For any* app launch, the landing page should automatically navigate to the role-based login screen after the specified delay (2-3 seconds) or upon user interaction.

**Validates: Requirements 1.5**

### Property 2: Role Selection Routes Correctly
*For any* role selection on the role-based login screen, selecting "I want to buy" should route to consumer authentication, and selecting "I want to sell" should route to merchant authentication.

**Validates: Requirements 2.5, 2.6**

### Property 3: Admin Role Excluded
*For any* role-based login screen display, the admin role option should not be present or accessible in the mobile app.

**Validates: Requirements 4.1, 4.2, 4.3**

### Property 4: Visual Consistency
*For any* screen in the authentication flow (landing page or role-based login), the color scheme should consistently use deep teal (#00615F) for primary elements and off-white (#F9F3F0 or #F6F6F6) for text and secondary elements.

**Validates: Requirements 1.2, 2.2, 3.2, 3.3**

### Property 5: Mobile Responsiveness
*For any* mobile device screen size or orientation, the landing page and role-based login screen should render all elements properly scaled, centered, and with appropriate touch-friendly sizing (minimum 48dp for buttons).

**Validates: Requirements 5.1, 5.2, 5.3, 5.4**

## Error Handling

**Scenarios**:
1. **Navigation Failure**: If route navigation fails, display error message and retry
2. **Image Loading**: If meals.png fails to load, use solid color fallback (deep teal)
3. **Timeout**: If auto-navigation delay exceeds threshold, allow manual navigation
4. **Role Mismatch**: If selected role doesn't match available auth flows, show error and return to role selection

**User Feedback**:
- Toast messages for errors
- Loading indicators during navigation
- Clear error messages with retry options

## Testing Strategy

### Unit Testing

Unit tests verify specific examples and edge cases:

1. **Landing Page Tests**:
   - Verify landing page renders with correct background color
   - Verify logo and text are displayed
   - Verify auto-navigation triggers after delay
   - Verify manual tap navigation works

2. **Role-Based Login Tests**:
   - Verify both role buttons are displayed
   - Verify button text is correct ("I want to buy" and "I want to sell")
   - Verify admin option is not present
   - Verify background image loads correctly
   - Verify button tap routes to correct auth flow

3. **Navigation Tests**:
   - Verify routes are correctly configured
   - Verify role-based routing logic works
   - Verify admin role is excluded from mobile app

### Property-Based Testing

Property-based tests verify universal properties using a testing framework (e.g., `test` package with custom generators):

1. **Property 1: Landing Page Auto-Navigation**
   - Generate random delay values within acceptable range
   - Verify navigation occurs after delay
   - Verify manual tap overrides auto-navigation

2. **Property 2: Role Selection Routes Correctly**
   - Generate random role selections
   - Verify each selection routes to correct auth flow
   - Verify no unexpected routes occur

3. **Property 3: Admin Role Excluded**
   - Verify admin role is not in available roles list
   - Verify admin option is not rendered on screen
   - Verify admin access is blocked

4. **Property 4: Visual Consistency**
   - Generate random screen states
   - Verify color values match specification
   - Verify text colors are readable on backgrounds

5. **Property 5: Mobile Responsiveness**
   - Generate random screen sizes and orientations
   - Verify elements scale appropriately
   - Verify touch targets meet minimum size requirements
   - Verify layout remains readable

**Testing Framework**: Flutter `test` package with custom widget testing utilities

**Minimum Iterations**: 100 per property-based test

**Test Execution**: Run tests with `flutter test` command
