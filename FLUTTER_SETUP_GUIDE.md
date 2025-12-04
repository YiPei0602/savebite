# Flutter Development Environment Setup Guide

## Current Status

### ✅ Completed
- **Flutter SDK**: v3.22.3 installed
- **Dart SDK**: v3.4.4 installed
- **VS Code**: Configured with Flutter extension
- **Chrome**: Available for web development
- **Java 17**: Installed via Homebrew
- **Flutter Dependencies**: All packages downloaded

### ⚠️ Action Required

#### 1. Configure Java 17 (CRITICAL for Android)
Run the setup script:
```bash
./setup_flutter_env.sh
```

Or manually add to `~/.zshrc`:
```bash
export JAVA_HOME=/opt/homebrew/opt/openjdk@17
export PATH="$JAVA_HOME/bin:$PATH"
```

Then reload your shell:
```bash
source ~/.zshrc
```

#### 2. Accept Android SDK Licenses (REQUIRED)
```bash
flutter doctor --android-licenses
```
- Press `y` and Enter for each license prompt
- There will be multiple licenses to accept

#### 3. Update Xcode (RECOMMENDED)
Your current Xcode version: **14.3.1**  
Flutter recommends: **15.0+**

**To update:**
1. Open App Store
2. Search for "Xcode"
3. Click "Update" (or "Get" if not installed)
4. This is a large download (~15GB+), so ensure you have:
   - Stable internet connection
   - Sufficient disk space (~40GB free recommended)

**Note:** You can develop for Android and Web without updating Xcode, but iOS/macOS development requires Xcode 15+.

#### 4. (Optional) Install Android Studio
While not strictly required, Android Studio provides:
- Better Android emulator management
- Visual layout editor
- Additional debugging tools

Download from: https://developer.android.com/studio

---

## Development Platforms Available

After completing the setup:

| Platform | Status | Requirements |
|----------|--------|--------------|
| **Android** | ✅ Ready (after licenses) | Java 17 + Android SDK licenses |
| **Web** | ✅ Ready | Chrome installed |
| **macOS Desktop** | ✅ Ready | Current setup sufficient |
| **iOS** | ⚠️ Needs Xcode 15+ | Update Xcode |
| **Linux Desktop** | ✅ Ready | Build tools installed |
| **Windows Desktop** | ✅ Ready | Build tools installed |

---

## Quick Start Commands

### Verify Setup
```bash
flutter doctor -v
```

### Create New Flutter Project
```bash
flutter create my_app
cd my_app
flutter run
```

### Run on Different Platforms
```bash
# Web
flutter run -d chrome

# macOS Desktop
flutter run -d macos

# Android (after accepting licenses)
flutter run -d android

# iOS (after Xcode update)
flutter run -d ios
```

### Get Dependencies
```bash
flutter pub get
```

### Update Dependencies
```bash
flutter pub upgrade
```

### Clean Build
```bash
flutter clean
flutter pub get
```

---

## Your SaveBite Project

Your project is already initialized at:
```
/Users/tanyipei/SaveBite
```

**Project Structure:**
- `lib/` - Dart source code
- `android/` - Android-specific configuration
- `ios/` - iOS-specific configuration
- `web/` - Web-specific configuration
- `macos/`, `linux/`, `windows/` - Desktop platforms
- `test/` - Unit and widget tests
- `pubspec.yaml` - Dependencies and project configuration

**To run your project:**
```bash
cd /Users/tanyipei/SaveBite
flutter run -d chrome  # For web
# or
flutter run -d macos   # For macOS desktop
```

---

## Troubleshooting

### Issue: "Android license status unknown"
**Solution:** Run `flutter doctor --android-licenses` and accept all licenses

### Issue: "Java version incompatible"
**Solution:** Ensure Java 17 is set:
```bash
echo $JAVA_HOME  # Should show /opt/homebrew/opt/openjdk@17
java -version    # Should show version 17
```

### Issue: "Xcode version too old"
**Solution:** Update Xcode via App Store or download from Apple Developer

### Issue: "No devices available"
**Solution:** 
- For web: Ensure Chrome is running
- For Android: Accept licenses and start emulator
- For iOS: Update Xcode and connect device
- For desktop: Should work automatically

---

## Next Steps After Setup

1. ✅ Run `./setup_flutter_env.sh`
2. ✅ Run `flutter doctor --android-licenses`
3. ✅ Run `flutter doctor -v` to verify
4. 🚀 Start coding: `flutter run -d chrome`
5. 📱 (Optional) Update Xcode for iOS development

---

## Useful Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Flutter Cookbook](https://docs.flutter.dev/cookbook)
- [Widget Catalog](https://docs.flutter.dev/development/ui/widgets)
- [Pub.dev Packages](https://pub.dev/)

---

**Last Updated:** December 4, 2024  
**Flutter Version:** 3.22.3  
**Dart Version:** 3.4.4
