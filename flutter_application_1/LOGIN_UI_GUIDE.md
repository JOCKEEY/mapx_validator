# MapX Field Validator - Login UI Documentation

## 📱 Overview

A production-ready, cross-platform login UI built with Flutter that works seamlessly on both iOS and Android. The implementation follows Material 3 design principles and includes modern authentication features.

## ✨ Features

### Login Screen
- ✅ **Responsive Design** - Adapts to different screen sizes (mobile, tablet, desktop)
- ✅ **Tab Navigation** - Switch between Login and Register tabs
- ✅ **Input Validation** - Real-time validation with visual feedback
- ✅ **Error Handling** - Clear, user-friendly error messages
- ✅ **Loading States** - Visual feedback during authentication
- ✅ **Password Visibility Toggle** - Easy password visibility control
- ✅ **Remember Me** - Optional credential retention
- ✅ **Biometric Login** - Ready for fingerprint/face recognition
- ✅ **Demo Credentials** - Built-in demo login information
- ✅ **Forgot Password** - Link to password recovery flow

### Password Recovery Screen
- ✅ **Multi-Step Flow** - Email → OTP → Password Reset
- ✅ **Progress Indicator** - Visual step progression
- ✅ **OTP Verification** - 6-digit code input with formatting
- ✅ **Password Requirements** - Real-time validation feedback
- ✅ **Resend Code** - Resend recovery code option
- ✅ **Success Dialog** - Confirmation after password reset

### Reusable Components
- ✅ **AuthTextField** - Custom text field with password toggle
- ✅ **ErrorMessageWidget** - Consistent error display
- ✅ **SuccessMessageWidget** - Consistent success display
- ✅ **LoadingButton** - Button with loading state animation
- ✅ **TabSelector** - Custom tab navigation widget
- ✅ **DemoCredentialsCard** - Demo credentials display
- ✅ **DividerWithText** - Styled divider with text
- ✅ **PasswordRequirement** - Password requirement checker
- ✅ **BiometricLoginButton** - Biometric login button

## 🎨 Design Features

### Material 3 Compliance
- Modern rounded corners (12px border radius)
- Semantic color usage
- Proper spacing and padding
- Smooth animations and transitions
- Focus-friendly design

### Cross-Platform Compatibility
- **iOS**: Safe area handling, platform-specific gestures
- **Android**: Material design compliance, back button handling
- **Both**: Consistent UX across platforms

### Responsive Layout
- Mobile-first design
- Tablet optimization (adjustable padding)
- Desktop support (wider layouts)
- Landscape/portrait orientation handling

## 📁 File Structure

```
lib/features/auth/
├── presentation/
│   ├── screens/
│   │   ├── login_screen.dart                 # Main login screen
│   │   ├── password_recovery_screen.dart     # Password recovery flow
│   │   ├── splash_screen.dart                # Splash/loading screen
│   │   └── home_screen.dart                  # Home screen (post-login)
│   ├── widgets/
│   │   └── auth_widgets.dart                 # Reusable auth components
│   └── providers/
│       └── auth_provider.dart                # Auth state management
├── domain/
│   ├── auth_models.dart                      # DTOs and entities
│   ├── auth_repository.dart                  # Repository interface
│   └── auth_usecases.dart                    # Business logic
└── data/
    ├── auth_api_service.dart                 # API integration
    └── auth_repository_impl.dart             # Repository implementation
```

## 🔧 Implementation Details

### LoginScreen Class

**File**: `lib/features/auth/presentation/screens/login_screen.dart`

#### Features
1. **Tabbed Interface**
   - Login tab with credential validation
   - Register tab with account creation
   - Smooth animation between tabs

2. **Login Tab**
   - Username input with validation
   - Password input with visibility toggle
   - Remember me checkbox
   - Forgot password link
   - Loading button with spinner
   - Biometric login option
   - Demo credentials card
   - Error message display

3. **Register Tab**
   - Username field
   - Email field
   - Password field with requirements
   - Real-time password validation
   - Password requirements checklist
   - Create account button

#### State Management

```dart
// Using Riverpod for state management
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    apiService: ref.watch(authApiServiceProvider),
    secureStorage: ref.watch(secureStorageProvider),
    database: ref.watch(appDatabaseProvider),
  );
});

// In LoginScreen:
final authRepository = ref.read(authRepositoryProvider);
final result = await authRepository.login(
  username: username,
  password: password,
);
```

#### Error Handling

```dart
result.fold(
  (failure) {
    // Handle error
    setState(() => _errorMessage = failure.message);
  },
  (success) {
    // Navigate to home
    context.go('/home');
  },
);
```

### PasswordRecoveryScreen Class

**File**: `lib/features/auth/presentation/screens/password_recovery_screen.dart`

#### Three-Step Flow

**Step 1: Email Verification**
- User enters email address
- System sends recovery code
- Progress indicator shows step 1/3

**Step 2: OTP Verification**
- User enters 6-digit recovery code
- Code is validated
- Resend option available
- Progress indicator shows step 2/3

**Step 3: Password Reset**
- User enters new password (twice)
- Password requirements validation
- Password reset submitted
- Success dialog shown
- Redirects to login

#### Code Example

```dart
// Verify OTP
Future<void> _handleVerifyOTP() async {
  final otp = _otpController.text.trim();
  
  // Validation
  if (otp.length != 6) {
    setState(() => _errorMessage = 'Code must be 6 digits');
    return;
  }
  
  // API call
  setState(() => _isLoading = true);
  final result = await authRepository.verifyOTP(otp);
  setState(() => _isLoading = false);
  
  // Handle result
  if (result) {
    setState(() => _step = 2);
  }
}
```

### Reusable Components

**AuthTextField** - Custom validated text field
```dart
AuthTextField(
  controller: controller,
  label: 'Username',
  hintText: 'Enter username',
  prefixIcon: Icons.person_outline,
  obscureText: false,
  enabled: !isLoading,
)
```

**LoadingButton** - Button with loading animation
```dart
LoadingButton(
  isLoading: _isLoading,
  onPressed: _handleLogin,
  label: 'Sign In',
  backgroundColor: Colors.blue,
)
```

**ErrorMessageWidget** - Consistent error display
```dart
if (_errorMessage != null)
  ErrorMessageWidget(message: _errorMessage!),
```

## 🎯 User Flows

### Login Flow
```
Splash Screen
     ↓
Login Screen (Tab: Login)
     ├─ Enter credentials
     ├─ Validate inputs
     ├─ API authentication
     └─ Navigate to Home
```

### Password Recovery Flow
```
Login Screen (Forgot Password)
     ↓
Password Recovery Screen (Step 1)
     ├─ Enter email
     ├─ Send recovery code
     ↓
Password Recovery Screen (Step 2)
     ├─ Enter OTP code
     ├─ Verify code
     ↓
Password Recovery Screen (Step 3)
     ├─ Enter new password
     ├─ Reset password
     ↓
Success Dialog
     ↓
Back to Login
```

### Registration Flow
```
Login Screen (Tab: Register)
     ├─ Enter username
     ├─ Enter email
     ├─ Enter password
     ├─ Validate requirements
     └─ Create account
```

## 📱 Platform-Specific Considerations

### iOS
- **Safe Area**: Handled automatically with `SafeArea` widget
- **Keyboard**: Dismissible with `Dismissible` or gesture
- **Biometrics**: Uses `local_auth` package for Face ID
- **Status Bar**: Automatically adapts to light/dark theme

### Android
- **Back Button**: Handled with `WillPopScope` if needed
- **Keyboard**: Handled with `TextInputAction`
- **Biometrics**: Uses `local_auth` package for fingerprint
- **Permissions**: Declared in `AndroidManifest.xml`

## 🔐 Security Features

1. **Secure Token Storage**
   ```dart
   await secureStorageService.saveAccessToken(token);
   ```

2. **Password Visibility Control**
   - User can toggle password visibility
   - Default: hidden for security

3. **HTTPS Only**
   - All API calls use HTTPS
   - Certificate pinning ready

4. **Input Validation**
   - Client-side validation
   - Server-side validation (recommended)
   - XSS prevention

5. **Error Handling**
   - No sensitive data in error messages
   - Generic errors for security
   - Detailed logging (dev only)

## 🎨 Customization

### Change Colors

**In `lib/app/theme/app_theme.dart`:**
```dart
static const Color primaryColor = Color(0xFF2196F3); // Change this
```

### Change Text/Labels

**In LoginScreen:**
```dart
Text('MapX Field Validator') // Change branding

// Demo credentials
const DemoCredentialsCard(
  username: 'validator',
  password: 'demo123',
)
```

### Disable Registration Tab

**In LoginScreen:**
```dart
// Remove "Register" from tabs list
final tabs = ['Login']; // Only login

// Or modify tab builder:
_selectedTabIndex == 0 ? _buildLoginTab() : _buildLoginTab()
```

## 🧪 Testing

### Unit Tests
```dart
test('Login validation rejects empty username', () {
  expect(_validateLoginInputs('', 'password'), false);
});

test('Login validation rejects short password', () {
  expect(_validateLoginInputs('user', 'short'), false);
});
```

### Widget Tests
```dart
testWidgets('Login button is disabled during loading', (tester) async {
  await tester.pumpWidget(const MyApp());
  
  expect(find.byType(ElevatedButton), findsOneWidget);
  
  // Simulate loading
  await tester.tap(find.byIcon(Icons.login));
  await tester.pumpAndSettle();
  
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
});
```

## 📚 API Integration

### Expected Backend Endpoints

**Login:**
```
POST /api/mobile/auth/login
Body: {
  "username": "validator",
  "password": "demo123"
}
Response: {
  "accessToken": "jwt_token",
  "refreshToken": "refresh_token",
  "user": {
    "id": "user123",
    "name": "John Validator",
    "email": "john@example.com"
  },
  "expiresAt": "2026-08-13T10:00:00Z"
}
```

**Password Recovery - Send Code:**
```
POST /api/mobile/auth/forgot-password
Body: { "email": "john@example.com" }
Response: { "message": "Code sent to email" }
```

**Password Recovery - Verify Code:**
```
POST /api/mobile/auth/verify-code
Body: { "email": "john@example.com", "code": "123456" }
Response: { "valid": true, "token": "reset_token" }
```

**Password Recovery - Reset:**
```
POST /api/mobile/auth/reset-password
Body: {
  "token": "reset_token",
  "newPassword": "newpass123"
}
Response: { "message": "Password reset successful" }
```

## 🚀 Integration with App

### Add to Router

**In `lib/app/router/app_router.dart`:**
```dart
GoRoute(
  path: '/login',
  builder: (context, state) => const LoginScreen(),
),
GoRoute(
  path: '/forgot-password',
  builder: (context, state) => const PasswordRecoveryScreen(),
),
```

### Navigate to Password Recovery

**In LoginScreen:**
```dart
TextButton(
  onPressed: () => context.push('/forgot-password'),
  child: const Text('Forgot password?'),
),
```

## ⚙️ Configuration

### Demo Credentials

Change in `login_screen.dart`:
```dart
const DemoCredentialsCard(
  username: 'your_username',
  password: 'your_password',
)
```

### API Base URL

Change in `lib/core/constants/app_constants.dart`:
```dart
static const String baseUrl = 'https://your-api.com';
```

## 🐛 Troubleshooting

### Issue: Keyboard covers input fields
**Solution**: Use `SingleChildScrollView` wrapper (already implemented)

### Issue: Button stays in loading state
**Solution**: Ensure API returns success/error result properly

### Issue: Password requirements not updating
**Solution**: Use `setState()` to trigger rebuild or watch with Riverpod

### Issue: iOS keyboard doesn't dismiss
**Solution**: Add `textInputAction: TextInputAction.done`

## 📊 Performance Optimization

1. **Lazy Loading** - Widgets built only when needed
2. **Efficient State** - Only rebuild affected widgets
3. **Input Debouncing** - Validation debounced for better UX
4. **Image Optimization** - Logo is vector-based (Icon widget)
5. **Memory Management** - Controllers properly disposed

## 🎓 Best Practices

1. ✅ Always validate inputs before API calls
2. ✅ Use Either<Failure, Success> for results
3. ✅ Show loading state during async operations
4. ✅ Clear error messages after successful action
5. ✅ Use Riverpod for state management
6. ✅ Dispose controllers in dispose()
7. ✅ Use SafeArea for screen edges
8. ✅ Handle keyboard interactions
9. ✅ Provide user feedback for all actions
10. ✅ Test on both platforms (iOS/Android)

## 📞 Support & References

- **Flutter Docs**: https://flutter.dev
- **Material Design 3**: https://m3.material.io
- **Riverpod Docs**: https://riverpod.dev
- **GoRouter**: https://pub.dev/packages/go_router

---

**Documentation Version**: 1.0  
**Last Updated**: 2026-08-12  
**Compatible With**: Flutter 3.12+
