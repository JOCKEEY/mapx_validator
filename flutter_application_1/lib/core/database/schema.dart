import 'package:drift/drift.dart';

/// Parcels table definition
class Parcels extends Table {
  TextColumn get id => text()();
  TextColumn get pin => text()(); // Parcel Identification Number
  TextColumn get tdNumber => text()(); // TD Number
  TextColumn get ownerName => text()();
  TextColumn get classification => text().nullable()();
  TextColumn get barangay => text().nullable()();
  TextColumn get municipality => text().nullable()();
  RealColumn get area => real().nullable()();
  TextColumn get geometryJson => text().nullable()(); // GeoJSON format
  RealColumn get centroidLat => real().nullable()();
  RealColumn get centroidLng => real().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get downloadedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {pin, tdNumber}, // Ensure unique parcel identification
      ];
}

/// Validations table definition
class Validations extends Table {
  TextColumn get id => text()();
  TextColumn get parcelId => text()();
  TextColumn get tdNumber => text().nullable()();
  TextColumn get status => text()(); // valid, needs_update, not_found, duplicate, other
  TextColumn get remarks => text().nullable()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  TextColumn get syncStatus =>
      text().withDefault(Constant('pending'))(); // pending, synced, failed, uploading
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime().nullable()();
  IntColumn get retryCount => integer().withDefault(Constant(0))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {parcelId, createdAt}, // One validation per parcel per time period
      ];
}

/// Validation photos table definition
class ValidationPhotos extends Table {
  TextColumn get id => text()();
  TextColumn get validationId => text()();
  TextColumn get localPath => text()(); // Local file path
  TextColumn get remotePath => text().nullable()(); // Remote URL after upload
  TextColumn get syncStatus =>
      text().withDefault(Constant('pending'))(); // pending, synced, failed
  TextColumn get fileName => text()();
  IntColumn get fileSizeBytes => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get uploadedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Sync queue table for background synchronization
class SyncQueues extends Table {
  TextColumn get id => text()();
  TextColumn get entityType =>
      text()(); // validation, photo, parcel (entity type)
  TextColumn get entityId => text()(); // ID of the entity to sync
  TextColumn get operation =>
      text()(); // create, update, delete (operation type)
  TextColumn get payloadJson => text()(); // JSON payload for the sync
  IntColumn get retryCount => integer().withDefault(Constant(0))();
  TextColumn get lastErrorMessage => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get processedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {
          entityType,
          entityId,
          operation
        }, // Prevent duplicate sync operations
      ];
}

/// Land parcels selected in the field for later validation
class RpuQueueItems extends Table {
  TextColumn get id => text()(); // land parcel id from the API
  TextColumn get pin => text()();
  TextColumn get tdNumber => text().nullable()();
  TextColumn get owner => text()();
  TextColumn get municipality => text().nullable()();
  TextColumn get barangay => text().nullable()();
  TextColumn get landClass => text().nullable()();
  TextColumn get payloadJson => text()(); // full search-result JSON
  DateTimeColumn get addedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// User sessions table for storing user info and authentication
class UserSessions extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get userName => text()();
  TextColumn get userEmail => text()();
  TextColumn get accessToken => text()();
  TextColumn get refreshToken => text().nullable()();
  DateTimeColumn get tokenExpiresAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get lastActivityAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {userId}, // One active session per user
      ];
}
