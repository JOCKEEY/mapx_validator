# MapX Field Validator - Developer Quick Reference

## 🚀 Quick Start (5 Minutes)

```bash
# 1. Navigate to project
cd c:\Users\User\OneDrive\Documents\mapx_validator\flutter_application_1

# 2. Generate code (REQUIRED - first time only)
flutter pub run build_runner build --delete-conflicting-outputs

# 3. Verify compilation
flutter analyze

# 4. Run the app
flutter run
```

## 📁 File Structure Quick Reference

```
lib/
├── main.dart                                      # Entry point
├── app.dart                                       # Main widget
├── router/app_router.dart                         # Routes
├── theme/app_theme.dart                           # Styling
├── providers/app_providers.dart                   # DI setup
│
├── core/
│   ├── constants/app_constants.dart              # Config
│   ├── database/
│   │   ├── schema.dart                           # Table definitions
│   │   └── app_database.dart                     # DAOs
│   ├── errors/failures.dart                      # Error types
│   ├── network/dio_setup.dart                    # HTTP client
│   ├── storage/secure_storage_service.dart       # Secure storage
│   ├── location/location_service.dart            # GPS
│   ├── maps/map_service.dart                     # Routing
│   └── sync/sync_queue_manager.dart              # Offline queue
│
├── features/
│   ├── auth/
│   │   ├── domain/
│   │   │   ├── auth_models.dart
│   │   │   ├── auth_repository.dart
│   │   │   └── auth_usecases.dart
│   │   ├── data/
│   │   │   ├── auth_api_service.dart
│   │   │   └── auth_repository_impl.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── splash_screen.dart
│   │       │   ├── login_screen.dart
│   │       │   └── home_screen.dart
│   │       └── providers/auth_provider.dart
│   │
│   ├── parcel/
│   │   ├── domain/
│   │   │   ├── parcel_models.dart
│   │   │   └── parcel_repository.dart
│   │   └── data/
│   │       ├── parcel_api_service.dart
│   │       └── parcel_repository_impl.dart
│   │
│   └── validation/
│       ├── domain/
│       │   ├── validation_models.dart
│       │   └── validation_repository.dart
│       └── data/
│           ├── validation_api_service.dart
│           └── validation_repository_impl_new.dart
```

## 🔑 Key Classes & Modules

### Authentication
- **File**: `features/auth/`
- **Entry Point**: `lib/features/auth/presentation/screens/login_screen.dart`
- **State**: `authStateProvider` (Riverpod)
- **Key Methods**:
  ```dart
  // Login
  await authRepository.login(username, password);
  
  // Logout
  await authRepository.logout();
  
  // Check auth status
  bool authenticated = await authRepository.isAuthenticated();
  ```

### Parcel Management
- **File**: `features/parcel/`
- **Key Methods**:
  ```dart
  // Search
  Either<Failure, List<ParcelSearchResult>> results = 
    await parcelRepository.searchParcels(query);
  
  // Get details
  Either<Failure, ParcelEntity> parcel = 
    await parcelRepository.getParcelById(id);
  
  // Cache
  await parcelRepository.cacheParcel(entity);
  ```

### Validation & Sync
- **File**: `features/validation/`
- **Sync Queue**: `core/sync/sync_queue_manager.dart`
- **Key Methods**:
  ```dart
  // Create validation
  await validationRepository.createValidation(request);
  
  // Add photo
  await validationRepository.addPhotoToValidation(
    validationId: id,
    localPath: imagePath,
  );
  
  // Sync to server
  await validationRepository.uploadValidation(validationId);
  ```

### Database
- **File**: `core/database/app_database.dart`
- **Tables**: Parcels, Validations, ValidationPhotos, SyncQueues, UserSessions
- **Example Query**:
  ```dart
  // Insert parcel
  await database.upsertParcel(
    ParcelsCompanion(
      id: drift.Value(id),
      pin: drift.Value(pin),
      // ... other fields
    ),
  );
  
  // Get parcel
  Parcel? parcel = await database.getParcelById(id);
  ```

## 🔌 Common Tasks

### Add a New Provider
```dart
// In app/providers/app_providers.dart
final myServiceProvider = Provider<MyService>((ref) {
  return MyService();
});
```

### Create a New Feature Screen
```dart
class MyScreen extends ConsumerWidget {
  const MyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Access providers
    final authState = ref.watch(authStateProvider);
    
    return Scaffold(
      appBar: AppBar(title: const Text('My Screen')),
      body: Center(child: Text(authState.toString())),
    );
  }
}
```

### Handle Errors
```dart
// Using Either (fpdart)
final result = await repository.someOperation();
result.fold(
  (failure) => print('Error: ${failure.message}'),
  (success) => print('Success: $success'),
);
```

### Database Query
```dart
// Get all pending validations
List<Validation> pending = 
  await database.getPendingValidations();

// Update validation
await database.updateValidationSyncStatus(id, 'synced');
```

### Add to Sync Queue
```dart
await syncQueueManager.addToQueue(
  entityType: 'validation',
  entityId: id,
  operation: 'create',
  payload: validationData,
);
```

## 🧪 Testing Structure

```
test/
├── domain/
│   ├── auth/
│   └── parcel/
├── data/
│   ├── auth/
│   └── parcel/
└── presentation/
    ├── auth/
    └── parcel/
```

### Sample Unit Test
```dart
test('LoginUseCase validates credentials', () async {
  // Arrange
  const credentials = LoginRequestDto(
    username: 'user',
    password: 'pass',
  );
  
  // Act
  final result = await usecase(credentials);
  
  // Assert
  expect(result.isRight(), true);
});
```

## 🔧 Common Commands

| Command | Purpose |
|---------|---------|
| `flutter pub get` | Install dependencies |
| `flutter pub run build_runner build` | Generate code |
| `flutter pub run build_runner watch` | Watch for changes |
| `flutter analyze` | Check code quality |
| `flutter test` | Run unit tests |
| `flutter run` | Run on device |
| `flutter run -d <device>` | Run on specific device |
| `flutter clean` | Clear build |
| `flutter doctor` | Check environment |

## 🎨 Naming Conventions

| Type | Pattern | Example |
|------|---------|---------|
| **File** | snake_case | `parcel_repository.dart` |
| **Class** | PascalCase | `ParcelRepository` |
| **Variable** | camelCase | `parcelId` |
| **Constant** | camelCase | `defaultTimeout` |
| **Screen** | [Feature]Screen | `LoginScreen` |
| **Provider** | [entity]Provider | `authStateProvider` |
| **Route** | /kebab-case | `/parcel-search` |

## 🐛 Debugging Tips

### Enable Debug Logging
```dart
// In main.dart
import 'package:flutter/foundation.dart';

if (kDebugMode) {
  print('Debug mode enabled');
}
```

### Database Inspector
```bash
# Check database file
flutter run --debug
# Database at: /data/data/com.example.app/databases/app.db
```

### Riverpod DevTools
```bash
flutter pub add riverpod_devtools
# Access at: http://localhost:8080
```

## 📋 Pre-Commit Checklist

- [ ] `flutter analyze` passes
- [ ] `flutter format lib/` applied
- [ ] Tests written for new code
- [ ] Comments added for complex logic
- [ ] No TODO comments left
- [ ] Error handling implemented

## 🚨 Troubleshooting Quick Links

**Issue**: Build fails with "uri_has_not_been_generated"
→ Run: `flutter pub run build_runner build`

**Issue**: App crashes on startup
→ Check: `flutter run` console for stack trace

**Issue**: Database not persisting
→ Verify: `flutter clean` then rebuild

**Issue**: Permissions denied
→ Update: AndroidManifest.xml and Info.plist

**Issue**: Build runner hangs
→ Try: `flutter pub run build_runner clean` then rebuild

## 📚 Documentation Links

- [ARCHITECTURE.md](./ARCHITECTURE.md) - System design
- [SETUP_GUIDE.md](./SETUP_GUIDE.md) - Development setup
- [IMPLEMENTATION_STATUS.md](./IMPLEMENTATION_STATUS.md) - Current status

## ✨ Code Style Examples

### Good Error Handling
```dart
try {
  final result = await api.fetch();
  return Right(result);
} catch (e) {
  return Left(NetworkFailure(e.toString()));
}
```

### Good State Management
```dart
final userProvider = StateNotifierProvider<UserNotifier, UserState>(
  (ref) => UserNotifier(ref.watch(userRepositoryProvider)),
);
```

### Good Widget Structure
```dart
class MyWidget extends ConsumerWidget {
  const MyWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myProvider);
    
    return state.when(
      data: (data) => _buildContent(data),
      loading: () => const LoadingWidget(),
      error: (err, _) => ErrorWidget(error: err),
    );
  }

  Widget _buildContent(MyData data) {
    return Text(data.toString());
  }
}
```

## 🎯 Performance Tips

1. **Use `.select()` in Riverpod** to rebuild only on relevant changes
2. **Cache API responses** in local database
3. **Paginate large lists** to reduce memory usage
4. **Compress images** before upload (already configured)
5. **Use `const` constructors** where possible
6. **Profile with DevTools** for slow builds

## 📞 Quick Reference Commands

```bash
# Full clean rebuild
flutter clean && flutter pub get && flutter pub run build_runner build

# Watch for changes during development
flutter pub run build_runner watch

# Format all code
flutter format lib/

# Analyze issues
flutter analyze --fatal-infos

# Run with specific flavor (if configured)
flutter run --flavor dev

# Build release APK
flutter build apk --release
```

---

**Last Updated**: 2026-08-12  
**Quick Reference Version**: 1.0  
**Flutter Version**: 3.12+
