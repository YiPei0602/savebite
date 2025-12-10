# Implementation Plan: Landing Page & Role-Based Authentication

- [ ] 1. Set up project structure and create landing page screen
  - Create `lib/screens/landing_page_screen.dart` with full-screen landing page widget
  - Display SaveBite logo (centered) with deep teal background (#00615F)
  - Display "SaveBite" text in off-white below logo
  - Implement auto-navigation to role-based login after 2-3 seconds
  - Allow manual tap to navigate immediately
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

- [ ] 1.1 Write unit tests for landing page
  - Test landing page renders with correct background color
  - Test logo and text are displayed
  - Test auto-navigation triggers
  - Test manual tap navigation works
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

- [ ] 1.2 Write property test for landing page auto-navigation
  - **Feature: landing-and-role-based-auth, Property 1: Landing Page Auto-Navigation**
  - **Validates: Requirements 1.5**

- [ ] 2. Create role-based login screen
  - Create `lib/screens/role_based_login_screen.dart` with role selection UI
  - Use meals.png as background image with semi-transparent overlay (40-50% opacity)
  - Display "I want to buy" button for consumer role
  - Display "I want to sell" button for merchant role
  - Ensure no admin role option is displayed
  - Style buttons with deep teal background and off-white text
  - Implement touch-friendly button sizing (minimum 48dp height)
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.7, 3.1, 3.2, 3.3, 3.4, 3.5_

- [ ] 2.1 Write unit tests for role-based login screen
  - Test both role buttons are displayed
  - Test button text is correct
  - Test admin option is not present
  - Test background image loads
  - Test button styling (colors, sizing, padding)
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.7, 3.1, 3.2, 3.3, 3.4, 3.5_

- [ ] 2.2 Write property test for admin role exclusion
  - **Feature: landing-and-role-based-auth, Property 3: Admin Role Excluded**
  - **Validates: Requirements 4.1, 4.2, 4.3**

- [ ] 2.3 Write property test for visual consistency
  - **Feature: landing-and-role-based-auth, Property 4: Visual Consistency**
  - **Validates: Requirements 1.2, 2.2, 3.2, 3.3**

- [ ] 3. Implement role-based navigation routing
  - Update `lib/core/router/app_router.dart` to add landing page route
  - Add role-based login route
  - Implement navigation logic from role selection to consumer/merchant auth flows
  - Update route guards to redirect unauthenticated users to landing page
  - Remove admin role from available roles enum
  - _Requirements: 2.5, 2.6, 4.1, 4.2, 4.3_

- [ ] 3.1 Write property test for role selection routing
  - **Feature: landing-and-role-based-auth, Property 2: Role Selection Routes Correctly**
  - **Validates: Requirements 2.5, 2.6**

- [ ] 4. Implement responsive design and mobile optimization
  - Ensure landing page elements are centered and properly scaled for all screen sizes
  - Ensure role-based login buttons are properly positioned and tappable
  - Test layout on different mobile device sizes and orientations
  - Verify font sizes meet minimum requirements (14sp for body text)
  - _Requirements: 5.1, 5.2, 5.3, 5.4_

- [ ] 4.1 Write property test for mobile responsiveness
  - **Feature: landing-and-role-based-auth, Property 5: Mobile Responsiveness**
  - **Validates: Requirements 5.1, 5.2, 5.3, 5.4**

- [ ] 5. Update app entry point and navigation flow
  - Modify `lib/main.dart` to route to landing page on first app launch
  - Ensure landing page is the initial route for unauthenticated users
  - Verify navigation flow: Landing Page → Role-Based Login → Auth Flow
  - _Requirements: 1.1, 2.1_

- [ ] 6. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 7. Final verification and integration
  - Test complete authentication flow from app launch through role selection
  - Verify landing page displays correctly on iOS and Android
  - Verify role-based login screen displays correctly on iOS and Android
  - Verify navigation between screens works smoothly
  - Verify no admin role appears in mobile app
  - Test on multiple device sizes and orientations
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 3.1, 3.2, 3.3, 3.4, 3.5, 4.1, 4.2, 4.3, 5.1, 5.2, 5.3, 5.4_
