import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';

import '../constants/app_constants.dart';
import '../database/app_database.dart';

/// Manages the sync queue for offline-first operations
class SyncQueueManager {
  final AppDatabase database;
  final _syncControllers = <String, StreamController<SyncStatus>>{};

  SyncQueueManager({required this.database});

  /// Add item to sync queue
  Future<void> addToQueue({
    required String entityType,
    required String entityId,
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    final syncQueueId = '${entityType}_${entityId}_${operation}_${DateTime.now().millisecondsSinceEpoch}';

    await database.insertSyncQueueItem(
      SyncQueuesCompanion(
        id: Value(syncQueueId),
        entityType: Value(entityType),
        entityId: Value(entityId),
        operation: Value(operation),
        payloadJson: Value(jsonEncode(payload)),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );

    _notifyListeners(entityId, SyncStatus.pending);
  }

  /// Get all pending sync items
  Future<List<SyncQueue>> getPendingItems() async {
    return await database.getPendingSyncItems();
  }

  /// Mark item as synced
  Future<void> markAsSynced(String syncQueueId) async {
    await database.markSyncItemAsProcessed(syncQueueId);
  }

  /// Mark item as failed
  Future<void> markAsFailed(String syncQueueId, String errorMessage) async {
    await database.updateSyncItemError(syncQueueId, errorMessage);
  }

  /// Retry failed items
  Future<void> retryFailedItems() async {
    // Get all failed items with retry count < max attempts
    final pendingItems = await database.getPendingSyncItems();

    for (final item in pendingItems) {
      if (item.retryCount < SyncConstants.maxRetryAttempts) {
        // Mark for retry
        await database.markSyncItemAsProcessed(item.id);
      }
    }
  }

  /// Clear processed items
  Future<void> clearProcessedItems() async {
    await database.clearProcessedSyncItems();
  }

  /// Get sync status stream for entity
  Stream<SyncStatus> getSyncStatusStream(String entityId) {
    if (!_syncControllers.containsKey(entityId)) {
      _syncControllers[entityId] = StreamController<SyncStatus>.broadcast();
    }
    return _syncControllers[entityId]!.stream;
  }

  /// Notify listeners of sync status change
  void _notifyListeners(String entityId, SyncStatus status) {
    if (_syncControllers.containsKey(entityId)) {
      _syncControllers[entityId]!.add(status);
    }
  }

  /// Cleanup resources
  void dispose() {
    for (final controller in _syncControllers.values) {
      controller.close();
    }
    _syncControllers.clear();
  }
}

/// Represents different sync statuses
enum SyncStatus {
  pending,
  uploading,
  synced,
  failed,
}
