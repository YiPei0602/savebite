# Requirements Document: Landing Page & Role-Based Authentication

## Introduction

SaveBite mobile app requires a redesigned authentication flow with a dedicated landing page and role-based login interface. The current authentication lacks visual distinction between consumer and merchant roles. This feature introduces a welcoming landing page showcasing the SaveBite brand, followed by a role-selection screen that guides users to either consumer ("I want to buy") or merchant ("I want to sell") authentication flows. The admin role is removed from mobile app as admin access will be managed through a separate web portal.

## Glossary

- **Landing Page**: Initial screen users see upon app launch, displaying the SaveBite brand and logo
- **Role-Based Login**: Authentication screen where users select their role (Consumer or Merchant) before proceeding to login/signup
- **Consumer Role**: User who purchases food items from merchants
- **Merchant Role**: User who sells food items to consumers
- **Admin Role**: Administrative user (removed from mobile app, handled via web portal)
- **Deep Teal**: Primary brand color (#00615F)
- **Off-White**: Secondary background color (#F9F3F0 or #F6F6F6)
- **Accent Colors**: Red, amber, and green used for promotions and urgency indicators
- **meals.png**: Background image asset used in role-based login screen

## Requirements

### Requirement 1

**User Story:** As a new user, I want to see a welcoming landing page when I first open the SaveBite app, so that I understand the app's purpose and brand identity.

#### Acceptance Criteria

1. WHEN the app launches for the first time THEN the system SHALL display a landing page with the SaveBite logo and brand name
2. WHEN the landing page is displayed THEN the system SHALL use deep teal (#00615F) as the background color
3. WHEN the landing page is displayed THEN the system SHALL display the SaveBite logo (flame with spoon/fork icon) centered on the screen
4. WHEN the landing page is displayed THEN the system SHALL display "SaveBite" text in off-white color below the logo
5. WHEN the user views the landing page THEN the system SHALL automatically navigate to the role-based login screen after 2-3 seconds or upon user tap

### Requirement 2

**User Story:** As a user, I want to select my role (buyer or seller) on the login screen, so that I can access the appropriate authentication flow for my use case.

#### Acceptance Criteria

1. WHEN the role-based login screen is displayed THEN the system SHALL show two distinct role selection buttons
2. WHEN the role-based login screen is displayed THEN the system SHALL use meals.png as the background image
3. WHEN the role-based login screen is displayed THEN the system SHALL display "I want to buy" button for the consumer role
4. WHEN the role-based login screen is displayed THEN the system SHALL display "I want to sell" button for the merchant role
5. WHEN a user taps the "I want to buy" button THEN the system SHALL route to the consumer login/signup flow
6. WHEN a user taps the "I want to sell" button THEN the system SHALL route to the merchant login/signup flow
7. WHEN the role-based login screen is displayed THEN the system SHALL NOT display an admin role option

### Requirement 3

**User Story:** As a designer, I want the role-based login screen to have proper visual hierarchy and readability, so that users can easily distinguish between the two role options.

#### Acceptance Criteria

1. WHEN the role-based login screen is displayed THEN the system SHALL apply a semi-transparent overlay to the meals.png background for text readability
2. WHEN the role-based login screen is displayed THEN the system SHALL use off-white (#F9F3F0 or #F6F6F6) for button text and labels
3. WHEN the role-based login screen is displayed THEN the system SHALL use deep teal (#00615F) for button backgrounds or borders
4. WHEN the role-based login screen is displayed THEN the system SHALL display buttons with sufficient padding and touch-friendly sizing (minimum 48dp height)
5. WHEN the role-based login screen is displayed THEN the system SHALL maintain consistent spacing and alignment between UI elements

### Requirement 4

**User Story:** As an admin user, I want the mobile app to remove admin authentication options, so that admin access is restricted to the web portal only.

#### Acceptance Criteria

1. WHEN the role-based login screen is displayed THEN the system SHALL NOT include an admin role button or option
2. WHEN the authentication flow is initialized THEN the system SHALL remove admin from the list of available roles in the mobile app
3. WHEN a user attempts to access admin features through the mobile app THEN the system SHALL prevent access and redirect to appropriate user role flows

### Requirement 5

**User Story:** As a user, I want the landing page and login screens to be responsive and properly formatted on mobile devices, so that the experience is optimized for my screen size.

#### Acceptance Criteria

1. WHEN the landing page is displayed on a mobile device THEN the system SHALL render all elements centered and properly scaled
2. WHEN the role-based login screen is displayed on a mobile device THEN the system SHALL ensure buttons are easily tappable and properly positioned
3. WHEN the app is rotated or resized THEN the system SHALL maintain proper layout and readability of all UI elements
4. WHEN the landing page or login screen is displayed THEN the system SHALL use appropriate font sizes for mobile readability (minimum 14sp for body text)
