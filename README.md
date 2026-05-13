# 🍽️ SaveBite - Food Rescue Platform

SaveBite connects **merchants** with surplus food to **consumers** who purchase rescue items at a discount, with pickup and delivery coordination on mobile.

![Flutter](https://img.shields.io/badge/Flutter-3.22.3-blue)
![Dart](https://img.shields.io/badge/Dart-3.4.4-blue)

---

## 🎯 Project Overview

1. **Merchants** — List surplus food at discounted prices and manage orders
2. **Consumers** — Discover deals, check out, and track pickup or delivery

---

## 🏗️ System Architecture

The system is built around **four** integrated product areas:

1. **User Profile & Personalized Impact Dashboard**
2. **Surplus Food Management & Discovery**
3. **Order & Payment Management**
4. **Delivery & Pickup Scheduling**

See [MODULES.md](MODULES.md) for detailed module documentation.

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

## 📱 Current Status

### ✅ Completed (UI)
- [x] Authentication (Login/Signup with role selection)
- [x] Home Screen (Browse surplus food)
- [x] Cart & Checkout Screens
- [x] Order Tracking & History
- [x] Impact Dashboard
- [x] Profile & Settings
- [x] Merchant Dashboard
- [x] Add/Manage Surplus Items
- [x] Payment Methods
- [x] Notifications

### ⏳ In Progress
- [ ] Firebase Integration
- [ ] Backend API Connection
- [ ] Real-time Data Updates

---

## 🏗️ Tech Stack

### Frontend
- **Framework**: Flutter
- **Language**: Dart
- **State Management**: Provider
- **Navigation**: go_router

### Backend (Planned)
- **Database**: Firebase Firestore
- **Authentication**: Firebase Auth
- **Storage**: Firebase Storage
- **Payment**: Stripe
- **Maps**: Google Maps API

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
│   ├── auth/                    # Module 1: Authentication
│   ├── profile/                 # Module 1: Profile & Impact
│   ├── marketplace/             # Module 2: Food Discovery
│   ├── merchant/                # Module 2: Merchant Management
│   ├── payment/                 # Module 3: Payment
│   ├── notifications/           # Module 3: Notifications
│   └── order/                   # Order tracking
├── models/                      # Data models
├── providers/                   # State management
└── services/                    # API services
```

See [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) for detailed structure explanation.

---

## 📖 Documentation

- [MODULES.md](MODULES.md) - Detailed module documentation
- [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) - Code structure guide
- [GETTING_STARTED.md](GETTING_STARTED.md) - Development setup guide

---

## 🎨 Design System

### Brand Colors
- **Primary (Jade Green)**: `#00A86B` - Headers, buttons, active states
- **Accent (Bright Orange)**: `#FF9F1C` - Discount tags, CTAs, highlights
- **Background**: `#F8F9FA` - Clean, minimal background

### Typography
- **Font**: Inter (Google Fonts)
- **Style**: Modern, clean, minimalist

### UI Principles
- Card-based layouts
- Rounded corners (12-16px)
- Prominent food imagery
- Inspired by GrabFood & Too Good To Go

---

## 🛠️ Development

### Code Style
- Follow [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Use `flutter_lints` for code quality

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

## 📄 License

Private - All rights reserved

---

**Built with ❤️ for a sustainable future**
