/// Represents different types of failures in the application
sealed class Failure {
  final String message;

  Failure(this.message);
}

/// Network-related failures
class NetworkFailure extends Failure {
  NetworkFailure(super.message);

  factory NetworkFailure.noInternet() =>
      NetworkFailure('No internet connection available');

  factory NetworkFailure.timeout() => NetworkFailure('Request timeout');

  factory NetworkFailure.serverError(int statusCode) =>
      NetworkFailure('Server error: $statusCode');

  factory NetworkFailure.parseError() => NetworkFailure('Failed to parse response');
}

/// Authentication-related failures
class AuthFailure extends Failure {
  AuthFailure(super.message);

  factory AuthFailure.invalidCredentials() =>
      AuthFailure('Invalid username or password');

  factory AuthFailure.tokenExpired() => AuthFailure('Session expired');

  factory AuthFailure.unauthorized() => AuthFailure('Unauthorized access');

  factory AuthFailure.noStoredCredentials() =>
      AuthFailure('No stored credentials found');
}

/// Cache-related failures
class CacheFailure extends Failure {
  CacheFailure(super.message);

  factory CacheFailure.notFound() => CacheFailure('Data not found in cache');

  factory CacheFailure.writeFailed() => CacheFailure('Failed to write to cache');
}

/// Location-related failures
class LocationFailure extends Failure {
  LocationFailure(super.message);

  factory LocationFailure.permissionDenied() =>
      LocationFailure('Location permission denied');

  factory LocationFailure.locationServiceDisabled() =>
      LocationFailure('Location service is disabled');

  factory LocationFailure.failedToObtainLocation() =>
      LocationFailure('Failed to obtain current location');
}

/// Validation-related failures
class ValidationFailure extends Failure {
  ValidationFailure(super.message);

  factory ValidationFailure.invalidInput() => ValidationFailure('Invalid input data');

  factory ValidationFailure.missingRequired(String field) =>
      ValidationFailure('Missing required field: $field');
}

/// Database-related failures
class DatabaseFailure extends Failure {
  DatabaseFailure(super.message);

  factory DatabaseFailure.operationFailed(String operation) =>
      DatabaseFailure('Database $operation operation failed');

  factory DatabaseFailure.notFound() =>
      DatabaseFailure('Record not found in database');
}

/// Sync-related failures
class SyncFailure extends Failure {
  SyncFailure(super.message);

  factory SyncFailure.uploadFailed() => SyncFailure('Failed to upload data');

  factory SyncFailure.downloadFailed() => SyncFailure('Failed to download data');

  factory SyncFailure.syncConflict() =>
      SyncFailure('Sync conflict detected. Please resolve manually.');
}

/// Unknown/Generic failures
class UnknownFailure extends Failure {
  UnknownFailure(super.message);

  factory UnknownFailure.fromException(Exception exception) =>
      UnknownFailure('An unexpected error occurred: ${exception.toString()}');
}
