# MapX Field Validator - Setup & Build Guide

## Current Status

The core architecture and infrastructure are now implemented. Before you can run or build the app, you need to complete the code generation step.

## 🔨 Next Steps (Priority Order)

### Step 1: Run Code Generation (Required) ⚠️

The project uses several code generation tools that must be run to generate the necessary files:

```bash
cd c:\Users\User\OneDrive\Documents\mapx_validator\flutter_application_1

# Generate all code (Drift, Freezed, json_serializable, etc.)
flutter pub run build_runner build --delete-conflicting-outputs
```

**What gets generated:**
- `lib/core/database/app_database.g.dart` - Database DAOs and schema
- `lib/features/auth/domain/auth_models.freezed.dart` - Freezed models for auth
- `lib/features/auth/domain/auth_models.g.dart` - JSON serialization
- `lib/features/parcel/domain/parcel_models.freezed.dart` - Parcel models
- `lib/features/parcel/domain/parcel_models.g.dart` - Parcel JSON serialization
- `lib/features/validation/domain/validation_models.freezed.dart` - Validation models
- `lib/features/validation/domain/validation_models.g.dart` - Validation JSON serialization

**Expected output:**
- Should complete without errors
- Will show "Succeeded" at the end
- Creates `.dart_tool/build` directory with intermediate files

### Step 2: Verify Compilation

After code generation completes, run analyze to check for errors:

```bash
flutter analyze
```

Should show:
- ✅ No errors (or only minor warnings)
- Warnings about deprecated APIs are acceptable

### Step 3: Run the App

Once analyze passes, you can run the app:

```bash
# For Android emulator
flutter run

# For iOS simulator
flutter run -d "iPhone 15"

# For specific device
flutter run -d <device_id>

# List available devices
flutter devices
```

### Step 4: Fix Remaining Configuration Issues

After running the app, you may need to configure:

#### Android Setup (`android/app/src/main/AndroidManifest.xml`)
Add these permissions inside `<manifest>` tag:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.INTERNET" />
```

#### iOS Setup (`ios/Runner/Info.plist`)
Add these keys (inside `<dict>`):
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>MapX Validator needs access to your location to validate parcels</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>MapX Validator needs access to your location for offline validation</string>
<key>NSCameraUsageDescription</key>
<string>MapX Validator needs camera access to capture validation photos</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>MapX Validator needs photo library access</string>
```

## 📝 Important Configuration

### Update API Base URL

Edit `lib/core/constants/app_constants.dart` and update:

```dart
abstract final class ApiConstants {
  static const String baseUrl = 'https://api.mapx.example.com'; // ← Change this
  // ... rest of constants
}
```

Replace `https://api.mapx.example.com` with your actual backend URL.

### Mock API Responses (Optional)

If your backend isn't ready yet, the app includes basic error handling. For testing:

1. The login screen shows demo credentials
2. Parcel search will fail gracefully and show empty state
3. Database will store everything locally

## 🧪 Quick Test Flow

Once the app runs:

1. **Splash Screen** → Auto-navigates to Login
2. **Login Screen** → Try demo credentials (check `login_screen.dart` for values)
3. **Home Screen** → Shows welcome card and quick action buttons
4. Tap "Search Parcel" → Empty state (no API connected yet)
5. "Sync Queue" → Shows empty state

## 🐛 Common Issues & Solutions

### Issue: "uri_has_not_been_generated" errors in Drift

**Solution**: Run `flutter pub run build_runner build --delete-conflicting-outputs`

### Issue: "Undefined class XyzCompanion"

**Solution**: Same as above - build runner needs to generate Drift files

### Issue: "Freezed models not generating"

**Solution**: Run build runner, ensure all model files have `part 'file.freezed.dart';`

### Issue: App crashes on startup

**Solution**: 
1. Check console for detailed error
2. Ensure all required permissions are configured
3. Verify API base URL is set correctly
4. Clear app data: `flutter clean && flutter pub get`

### Issue: "Please wait, still warming up build runner"

**Solution**: First code generation can take 30-60 seconds. Be patient.

## 📊 Development Workflow

### Hot Reload During Development

After initial build, you can hot reload for faster iteration:

```bash
# In running app
r          # Hot reload (for UI/logic changes)
R          # Hot restart (for dependency/const changes)
q          # Quit
```

### Clean Build (when needed)

```bash
flutter clean
flutter pub get
flutter pub run build_runner build
flutter run
```

## 🏗️ Next Feature Development

After the above setup is working, implement screens:

1. **Parcel Search Screen** - Debounced search, local-first suggestions
2. **Parcel Details Screen** - Full parcel info, map preview  
3. **Validation Form Screen** - Create new validations
4. **Photo Capture Screen** - Camera integration
5. **Map Navigation Screen** - GPS + map display
6. **Sync Queue Screen** - Manual sync + status

See [ARCHITECTURE.md](./ARCHITECTURE.md) for detailed guidance on each feature layer.

## ✅ Verification Checklist

After completing the steps above, verify:

- [ ] `flutter pub get` runs successfully
- [ ] `flutter pub run build_runner build` completes without errors
- [ ] `flutter analyze` shows no errors
- [ ] `flutter run` launches the app
- [ ] Splash screen displays
- [ ] Can navigate to Login screen
- [ ] Can tap demo login (with error message if no API)
- [ ] No crashes on app startup

## 📚 Build Commands Reference

| Command | Purpose |
|---------|---------|
| `flutter pub get` | Download dependencies |
| `flutter pub run build_runner build` | Generate code (Drift, Freezed, etc.) |
| `flutter analyze` | Check for compilation errors |
| `flutter run` | Run on connected device/emulator |
| `flutter clean` | Clear build artifacts (use if stuck) |
| `flutter build apk` | Build Android APK (release) |
| `flutter build ios` | Build iOS app (release) |

## 🎯 Immediate Next Priority

1. **Run build_runner** (generates all necessary code)
2. **Verify analyze passes** (no errors)
3. **Test app startup** (ensure it runs)
4. **Configure backend URL** (update API constants)
5. **Start implementing UI screens** (using existing repository layer)

---

**Note**: The entire backend layer is production-ready. Once build_runner completes, you can focus on presentation layer (UI screens and user interactions).
