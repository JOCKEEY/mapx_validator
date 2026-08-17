/// API endpoints and configuration constants
abstract final class ApiConstants {
  // Base URL - should be configured per environment
  static const String baseUrl = 'https://api.mapx.example.com';

  // Authentication endpoints
  static const String loginEndpoint = '/api/mobile/auth/login';
  static const String logoutEndpoint = '/api/mobile/auth/logout';
  static const String refreshTokenEndpoint = '/api/mobile/auth/refresh';

  // Parcel endpoints
  static const String searchParcelsEndpoint = '/api/mobile/parcels/search';
  static const String parcelDetailsEndpoint = '/api/mobile/parcels';
  static const String offlineParcelsEndpoint = '/api/mobile/parcels/offline';
  static const String suggestParcelsEndpoint = '/api/mobile/parcels/suggest';

  // Validation endpoints
  static const String uploadValidationEndpoint = '/api/mobile/validations';
  static const String getValidationEndpoint = '/api/mobile/validations';
  static const String listValidationsEndpoint = '/api/mobile/validations';

  // Timeout constants
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Headers
  static const String contentTypeJson = 'application/json';
  static const String contentTypeFormData = 'multipart/form-data';
}

/// Storage keys for secure storage and preferences
abstract final class StorageKeys {
  // Auth tokens
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String tokenExpiresAt = 'token_expires_at';

  // User info
  static const String userId = 'user_id';
  static const String userName = 'user_name';
  static const String userEmail = 'user_email';

  // App preferences
  static const String lastSyncTime = 'last_sync_time';
  static const String offlineMode = 'offline_mode';
  static const String preferredMapProvider = 'preferred_map_provider';
  static const String locationAccuracy = 'location_accuracy';

  // Camera preferences
  static const String cameraQuality = 'camera_quality';
  static const String imageCompressionQuality = 'image_compression_quality';
}

/// Database table names
abstract final class DatabaseTables {
  static const String parcels = 'parcels';
  static const String validations = 'validations';
  static const String validationPhotos = 'validation_photos';
  static const String syncQueue = 'sync_queue';
  static const String userSessions = 'user_sessions';
}

/// Validation statuses
abstract final class ValidationStatus {
  static const String valid = 'valid';
  static const String needsUpdate = 'needs_update';
  static const String notFound = 'not_found';
  static const String duplicate = 'duplicate';
  static const String other = 'other';

  static const List<String> all = [
    valid,
    needsUpdate,
    notFound,
    duplicate,
    other,
  ];
}

/// Sync statuses
abstract final class SyncStatus {
  static const String pending = 'pending';
  static const String synced = 'synced';
  static const String failed = 'failed';
  static const String uploading = 'uploading';

  static const List<String> all = [
    pending,
    synced,
    failed,
    uploading,
  ];
}

/// Entity types for sync queue
abstract final class EntityType {
  static const String validation = 'validation';
  static const String photo = 'photo';
  static const String parcel = 'parcel';
}

/// Operation types for sync queue
abstract final class OperationType {
  static const String create = 'create';
  static const String update = 'update';
  static const String delete = 'delete';
}

/// Location tracking constants
abstract final class LocationConstants {
  static const double minDistanceFilter = 5.0; // meters
  static const double accuracyThreshold = 20.0; // meters
  static const double parcelArrivalThreshold = 10.0; // meters
}

/// Background sync constants
abstract final class SyncConstants {
  static const Duration syncInterval = Duration(minutes: 15);
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 10);
  static const int maxBatchUploadSize = 5; // validations per batch
}

/// Image compression constants
abstract final class ImageConstants {
  static const int maxImageWidth = 1600;
  static const int jpegQuality = 75;
  static const int thumbnailSize = 256;
}

/// App configuration
abstract final class AppConfig {
  static const String appName = 'MapX Field Validator';
  static const String appVersion = '1.0.0';
  static const bool enableLogging = true;
  static const bool enableCrashReporting = true;
}
