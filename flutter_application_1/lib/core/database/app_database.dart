import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

import 'schema.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Parcels, Validations, ValidationPhotos, SyncQueues, UserSessions],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // ===== PARCEL DAOS =====

  /// Insert or update a parcel
  Future<void> upsertParcel(ParcelsCompanion parcel) async {
    await into(parcels).insertOnConflictUpdate(parcel);
  }

  /// Get parcel by ID
  Future<Parcel?> getParcelById(String id) async {
    return (select(parcels)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  /// Search parcels by PIN or TD Number
  Future<List<Parcel>> searchParcels(String query) async {
    final lowerQuery = '%${query.toLowerCase()}%';
    return (select(parcels)
          ..where((tbl) =>
              tbl.pin.like(lowerQuery) |
              tbl.tdNumber.like(lowerQuery))
          ..limit(20))
        .get();
  }

  /// Get all parcels
  Future<List<Parcel>> getAllParcels() {
    return select(parcels).get();
  }

  /// Delete parcel by ID
  Future<int> deleteParcelById(String id) {
    return (delete(parcels)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Clear all parcels
  Future<int> clearAllParcels() {
    return delete(parcels).go();
  }

  // ===== VALIDATION DAOS =====

  /// Insert a new validation
  Future<void> insertValidation(ValidationsCompanion validation) async {
    await into(validations).insert(validation);
  }

  /// Update validation
  Future<bool> updateValidation(ValidationsCompanion validation) {
    return update(validations).replace(validation);
  }

  /// Get validation by ID
  Future<Validation?> getValidationById(String id) async {
    return (select(validations)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  /// Get all validations for a parcel
  Future<List<Validation>> getValidationsByParcelId(String parcelId) {
    return (select(validations)
          ..where((tbl) => tbl.parcelId.equals(parcelId))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  /// Get pending validations (not yet synced)
  Future<List<Validation>> getPendingValidations() {
    return (select(validations)
          ..where((tbl) => tbl.syncStatus.equals('pending'))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.createdAt)]))
        .get();
  }

  /// Get failed validations
  Future<List<Validation>> getFailedValidations() {
    return (select(validations)
          ..where((tbl) => tbl.syncStatus.equals('failed'))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.retryCount, mode: OrderingMode.desc)]))
        .get();
  }

  /// Update validation sync status
  Future<bool> updateValidationSyncStatus(
    String validationId,
    String syncStatus,
  ) async {
    final result = await (update(validations)..where((tbl) => tbl.id.equals(validationId)))
        .write(
          ValidationsCompanion(
            syncStatus: Value(syncStatus),
            updatedAt: Value(DateTime.now()),
          ),
        );
    return result > 0;
  }

  /// Increment retry count for validation
  Future<bool> incrementValidationRetryCount(String validationId) async {
    final validation = await getValidationById(validationId);
    if (validation == null) return false;

    return updateValidation(
      validation.toCompanion(false).copyWith(
            retryCount: Value(validation.retryCount + 1),
            updatedAt: Value(DateTime.now()),
          ),
    );
  }

  /// Delete validation by ID
  Future<int> deleteValidationById(String id) {
    return (delete(validations)..where((tbl) => tbl.id.equals(id))).go();
  }

  // ===== VALIDATION PHOTO DAOS =====

  /// Insert validation photo
  Future<void> insertValidationPhoto(ValidationPhotosCompanion photo) async {
    await into(validationPhotos).insert(photo);
  }

  /// Get photos for validation
  Future<List<ValidationPhoto>> getPhotosByValidationId(String validationId) {
    return (select(validationPhotos)
          ..where((tbl) => tbl.validationId.equals(validationId))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.createdAt)]))
        .get();
  }

  /// Get pending photos (not yet synced)
  Future<List<ValidationPhoto>> getPendingPhotos() {
    return (select(validationPhotos)
          ..where((tbl) => tbl.syncStatus.equals('pending'))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.createdAt)]))
        .get();
  }

  /// Update photo sync status
  Future<bool> updatePhotoSyncStatus(String photoId, String syncStatus) async {
    final result = await (update(validationPhotos)..where((tbl) => tbl.id.equals(photoId)))
        .write(
          ValidationPhotosCompanion(
            syncStatus: Value(syncStatus),
            uploadedAt: Value(DateTime.now()),
          ),
        );
    return result > 0;
  }

  /// Delete photo by ID
  Future<int> deletePhotoById(String id) {
    return (delete(validationPhotos)..where((tbl) => tbl.id.equals(id))).go();
  }

  // ===== SYNC QUEUE DAOS =====

  /// Insert sync queue item
  Future<void> insertSyncQueueItem(SyncQueuesCompanion item) async {
    await into(syncQueues).insertOnConflictUpdate(item);
  }

  /// Get all pending sync items
  Future<List<SyncQueue>> getPendingSyncItems() {
    return (select(syncQueues)
          ..where((tbl) => tbl.processedAt.isNull())
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.createdAt)]))
        .get();
  }

  /// Get sync items by entity
  Future<List<SyncQueue>> getSyncItemsByEntity(
    String entityType,
    String entityId,
  ) {
    return (select(syncQueues)
          ..where((tbl) =>
              tbl.entityType.equals(entityType) & tbl.entityId.equals(entityId)))
        .get();
  }

  /// Mark sync item as processed
  Future<bool> markSyncItemAsProcessed(String syncQueueId) async {
    final result = await (update(syncQueues)..where((tbl) => tbl.id.equals(syncQueueId)))
        .write(
          SyncQueuesCompanion(
            processedAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ),
        );
    return result > 0;
  }

  /// Update sync item error
  Future<bool> updateSyncItemError(String syncQueueId, String errorMessage) async {
    final result = await (update(syncQueues)..where((tbl) => tbl.id.equals(syncQueueId)))
        .write(
          SyncQueuesCompanion(
            lastErrorMessage: Value(errorMessage),
            updatedAt: Value(DateTime.now()),
          ),
        );
    return result > 0;
  }

  /// Delete sync item
  Future<int> deleteSyncItem(String id) {
    return (delete(syncQueues)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Clear processed sync items
  Future<int> clearProcessedSyncItems() {
    return (delete(syncQueues)..where((tbl) => tbl.processedAt.isNotNull()))
        .go();
  }

  // ===== USER SESSION DAOS =====

  /// Insert or update user session
  Future<void> upsertUserSession(UserSessionsCompanion session) async {
    await into(userSessions).insertOnConflictUpdate(session);
  }

  /// Get active user session
  Future<UserSession?> getActiveUserSession() async {
    return (select(userSessions)
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Get user session by ID
  Future<UserSession?> getUserSessionById(String id) async {
    return (select(userSessions)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  /// Delete user session
  Future<int> deleteUserSession(String id) {
    return (delete(userSessions)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Clear all sessions
  Future<int> clearAllSessions() {
    return delete(userSessions).go();
  }

  /// Update session last activity
  Future<bool> updateSessionLastActivity(String sessionId) async {
    final result = await (update(userSessions)..where((tbl) => tbl.id.equals(sessionId)))
        .write(UserSessionsCompanion(lastActivityAt: Value(DateTime.now())));
    return result > 0;
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'mapx_validator.db'));
    if (kDebugMode) {
      print('Database path: ${file.path}');
    }
    return NativeDatabase(file);
  });
}
