# 🍽️ SaveBite - Food Rescue Platform

**SaveBite** is a mobile application designed to minimize food waste in Malaysia by connecting merchants with surplus food to consumers and NGOs.

![Flutter](https://img.shields.io/badge/Flutter-3.22.3-blue)
![Dart](https://img.shields.io/badge/Dart-3.4.4-blue)
![License](https://img.shields.io/badge/License-Private-red)

---

## 🎯 Project Overview

SaveBite connects three key stakeholders:
1. **Merchants** - List surplus food at discounted prices or donate it
2. **Consumers** - Buy surplus food at discounts or pick it up for free
3. **NGOs** - Receive automated donations of unsold food

---

## 🎨 Design System

### Brand Colors
- **Primary (Jade Green)**: `#00A86B` - Headers, buttons, active states
- **Accent (Bright Orange)**: `#FF9F1C` - Discount tags, CTAs, highlights
- **Background**: `#F8F9FA` - Clean, minimal background

### Typography
- **Font**: Poppins (Google Fonts)
- **Style**: Modern, clean, minimalist

### UI Principles
- Card-based layouts
- Rounded corners (12-16px)
- Prominent food imagery
- Inspired by GrabFood & Too Good To Go

---

## 🚀 Quick Start

### Prerequisites
- Flutter 3.22.3+
- Dart 3.4.4+
- Java 17 (for Android development)
- Xcode 15+ (for iOS development)

### Installation

1. **Clone the repository**
```bash
git clone <repository-url>
cd SaveBite
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Run the app**
```bash
# Web
flutter run -d chrome

# macOS Desktop
flutter run -d macos

# Android
flutter run -d android

# iOS
flutter run -d ios
```

---

## 📱 Features

### ✅ Completed (UI)
- [x] Authentication (Login/Signup with role selection)
- [x] Marketplace (Browse surplus food items)
- [x] Impact Dashboard (Track meals saved, CO₂ reduced, money saved)
- [x] Profile & Settings
- [x] Design System (Colors, Typography, Themes)
- [x] Reusable UI Components

### ⏳ In Progress
- [ ] Firebase Integration
- [ ] Backend API Connection
- [ ] Real-time Data

### 📋 Planned
- [ ] Shopping Cart & Checkout
- [ ] Stripe Payment Integration
- [ ] Google Maps Integration
- [ ] Push Notifications
- [ ] Merchant Dashboard
- [ ] NGO Features
- [ ] Smart Donation System

---

## 🏗️ Tech Stack

### Frontend
- **Framework**: Flutter
- **Language**: Dart
- **State Management**: Provider
- **Navigation**: go_router

### Backend (Planned)
- **API**: Node.js
- **Database**: Firebase Firestore
- **Authentication**: Firebase Auth
- **Storage**: Firebase Storage
- **Payment**: Stripe
- **Maps**: Google Maps API

### Key Packages
- `google_fonts` - Typography
- `cached_network_image` - Image optimization
- `firebase_core`, `firebase_auth`, `cloud_firestore` - Backend
- `flutter_stripe` - Payments
- `google_maps_flutter` - Maps
- `provider` - State management

---

## 📂 Project Structure

```
lib/
├── main.dart                    # App entry point
├── core/                        # Shared utilities
│   ├── theme/                   # Colors, typography, theme
│   ├── constants/               # App constants
│   ├── widgets/                 # Reusable components
│   └── router/                  # Navigation
├── features/                    # Feature modules
│   ├── auth/                    # Authentication
│   ├── marketplace/             # Food marketplace
│   ├── impact/                  # Impact dashboard
│   └── profile/                 # User profile
├── models/                      # Data models
├── services/                    # API services
└── providers/                   # State management
```

See [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) for detailed documentation.

---

## 🎯 Core Modules

### Module 1: User & Impact
- Role-based authentication (Merchant/Consumer/NGO)
- Profile management
- Personalized impact dashboard

### Module 2: Marketplace
- Browse surplus food items
- Filter by category and location
- Dynamic pricing display

### Module 3: Order & Payment
- Shopping cart
- Stripe checkout
- Order history

### Module 4: Fulfillment
- Self-pickup scheduling
- Live order tracking

### Module 5: Smart Donation
- Automated donation prompts
- NGO integration

---

## 🛠️ Development

### Code Style
- Follow [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Use `flutter_lints` for code quality
- Document public APIs

### Running Tests
```bash
flutter test
```

### Build for Production
```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

---

## 📖 Documentation

- [Project Structure](PROJECT_STRUCTURE.md) - Detailed architecture
- [Flutter Setup Guide](FLUTTER_SETUP_GUIDE.md) - Environment setup
- [Flutter Docs](https://docs.flutter.dev/) - Official documentation

---

## 🤝 Contributing

This is a private project. For team members:
1. Create a feature branch
2. Make your changes
3. Submit a pull request
4. Wait for code review

---

## 📄 License

Private - All rights reserved

---

## 📞 Contact

For questions or support, contact the development team.

---

**Built with ❤️ for a sustainable future**
