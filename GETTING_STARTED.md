# 🚀 Getting Started with SaveBite

A quick guide to set up and run the SaveBite project.

---

## 📋 Prerequisites

Before you begin, make sure you have:

- **Flutter SDK** 3.22.3 or higher
- **Dart SDK** 3.4.4 or higher
- **Java 17** (for Android development)
- **Xcode 15+** (for iOS development on macOS)
- **Android Studio** or **VS Code** with Flutter extensions
- **Git** (for version control)

---

## 🔧 Installation Steps

### 1. Clone the Repository

```bash
git clone <repository-url>
cd SaveBite
```

### 2. Install Dependencies

```bash
flutter pub get
```

This will install all required packages listed in `pubspec.yaml`.

### 3. Verify Installation

```bash
flutter doctor
```

This checks your Flutter setup and shows any missing dependencies.

---

## 🏃 Running the App

### Web (Chrome)

```bash
flutter run -d chrome
```

### macOS Desktop

```bash
flutter run -d macos
```

### Android

```bash
flutter run -d android
```

Make sure you have an Android emulator running or a device connected.

### iOS (macOS only)

```bash
flutter run -d ios
```

Make sure you have an iOS simulator running or a device connected.

---

## 📱 Testing Different Flows

### Consumer Flow

1. Run the app
2. Navigate to Login screen
3. Select "I'm a Consumer" role
4. Browse home screen
5. Add items to cart
6. Checkout and track order

### Merchant Flow

1. Run the app
2. Navigate to Login screen
3. Select "I'm a Merchant" role
4. View merchant dashboard
5. Add surplus items
6. Manage orders

### Admin Flow

1. Run the app
2. Navigate to Login screen
3. Select "I'm an Admin" role
4. View admin dashboard

---

## 🛠️ Development Tips

### Hot Reload

While the app is running, press `r` in the terminal to hot reload changes.

### Hot Restart

Press `R` (capital R) to hot restart the app.

### Stop the App

Press `q` to quit the app.

### View Logs

Check the terminal output for debug logs and errors.

---

## 📂 Project Structure

- `lib/main.dart` - App entry point
- `lib/screens/` - Main app screens
- `lib/features/` - Feature modules
- `lib/models/` - Data models
- `lib/providers/` - State management
- `lib/services/` - API services
- `lib/core/` - Core utilities (theme, router, widgets)

See [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) for detailed structure explanation.

---

## 🧪 Running Tests

```bash
flutter test
```

---

## 📦 Building for Production

### Android APK

```bash
flutter build apk --release
```

### iOS

```bash
flutter build ios --release
```

### Web

```bash
flutter build web --release
```

---

## 🐛 Troubleshooting

### Common Issues

#### 1. Dependencies Not Installing

```bash
flutter clean
flutter pub get
```

#### 2. Build Errors

```bash
flutter clean
flutter pub get
flutter run
```

#### 3. iOS Build Issues

Make sure you've run:
```bash
cd ios
pod install
cd ..
```

#### 4. Android Build Issues

Make sure you have:
- Android SDK installed
- JAVA_HOME set correctly
- Gradle properly configured

---

## 📚 Additional Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Documentation](https://dart.dev/guides)
- [MODULES.md](MODULES.md) - Module documentation
- [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) - Code structure guide

---

## 🆘 Need Help?

- Check the [Flutter documentation](https://docs.flutter.dev/)
- Review [MODULES.md](MODULES.md) for feature details
- Review [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) for code organization

---

**Happy coding! 🚀**

