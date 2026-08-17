import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/errors/failures.dart';
import '../../../core/sync/sync_queue_manager.dart';
import '../domain/validation_models.dart';
import '../domain/validation_repository.dart';
import 'validation_api_service.dart';

/// Implementation of ValidationRepository
class ValidationRepositoryImpl implements ValidationRepository {
  final ValidationApiService apiService;
  final AppDatabase database;
  final SyncQueueManager syncQueueManager;

  ValidationRepositoryImpl({
    required this.apiService,
    required this.database,
    required this.syncQueueManager,
  });

  @override
  Future<Either<Failure, ValidationEntity>> createValidation({
    required CreateValidationRequest request,
  }) async {
    try {
      const uuid = Uuid();
      final validationId = uuid.v4();

      // Create validation entity
      final validation = Validation(
        id: validationId,
        parcelId: request.parcelId,
        status: request.status,
        remarks: request.remarks,
        latitude: request.latitude,
        longitude: request.longitude,
        syncStatus: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncedAt: null,
        retryCount: 0,
      );

      // Save to database
      await database.insertValidation(
        ValidationsCompanion(
          id: Value(validation.id),
          parcelId: Value(validation.parcelId),
          status: Value(validation.status),
          remarks: Value(validation.remarks),
          latitude: Value(validation.latitude),
          longitude: Value(validation.longitude),
          syncStatus: Value(validation.syncStatus),
          createdAt: Value(validation.createdAt),
          updatedAt: Value(validation.updatedAt),
          retryCount: Value(validation.retryCount),
        ),
      );

      // Add to sync queue
      await syncQueueManager.addToQueue(
        entityType: 'validation',
        entityId: validationId,
        operation: 'create',
        payload: {
          'parcel_id': request.parcelId,
          'status': request.status,
          'remarks': request.remarks,
          'latitude': request.latitude,
          'longitude': request.longitude,
        },
      );

      // Return entity
      return Right(
        ValidationEntity(
          id: validationId,
          parcelId: request.parcelId,
          status: request.status,
          remarks: request.remarks,
          latitude: request.latitude,
          longitude: request.longitude,
          createdAt: DateTime.now(),
          photoIds: [],
        ),
      );
    } on Exception catch (e) {
      return Left(ValidationFailure('Failed to create validation: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, ValidationEntity>> getValidationById({
    required String validationId,
  }) async {
    try {
      final validation = await database.getValidationById(validationId);
      if (validation == null) {
        return Left(ValidationFailure('Validation not found'));
      }

      // Get associated photos
      final photos = await database.getPhotosByValidationId(validationId);

      return Right(
        ValidationEntity(
          id: validation.id,
          parcelId: validation.parcelId,
          status: validation.status,
          remarks: validation.remarks,
          latitude: validation.latitude,
          longitude: validation.longitude,
          createdAt: validation.createdAt,
          photoIds: photos.map((p) => p.id).toList(),
        ),
      );
    } on Exception catch (e) {
      return Left(ValidationFailure('Failed to get validation: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<ValidationEntity>>> getValidationsByParcelId({
    required String parcelId,
  }) async {
    try {
      final validations =
          await database.getValidationsByParcelId(parcelId);

      final entities = <ValidationEntity>[];
      for (final validation in validations) {
        final photos =
            await database.getPhotosByValidationId(validation.id);
        entities.add(
          ValidationEntity(
            id: validation.id,
            parcelId: validation.parcelId,
            status: validation.status,
            remarks: validation.remarks,
            latitude: validation.latitude,
            longitude: validation.longitude,
            createdAt: validation.createdAt,
            photoIds: photos.map((p) => p.id).toList(),
          ),
        );
      }

      return Right(entities);
    } on Exception catch (e) {
      return Left(ValidationFailure(
          'Failed to get validations: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<ValidationEntity>>>
      getPendingValidations() async {
    try {
      final validations = await database.getPendingValidations();

      final entities = <ValidationEntity>[];
      for (final validation in validations) {
        final photos =
            await database.getPhotosByValidationId(validation.id);
        entities.add(
          ValidationEntity(
            id: validation.id,
            parcelId: validation.parcelId,
            status: validation.status,
            remarks: validation.remarks,
            latitude: validation.latitude,
            longitude: validation.longitude,
            createdAt: validation.createdAt,
            photoIds: photos.map((p) => p.id).toList(),
          ),
        );
      }

      return Right(entities);
    } on Exception catch (e) {
      return Left(ValidationFailure(
          'Failed to get pending validations: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updateValidation({
    required ValidationEntity validation,
  }) async {
    try {
      await database.updateValidation(
        ValidationsCompanion(
          id: Value(validation.id),
          parcelId: Value(validation.parcelId),
          status: Value(validation.status),
          remarks: Value(validation.remarks),
          latitude: Value(validation.latitude),
          longitude: Value(validation.longitude),
          updatedAt: Value(DateTime.now()),
        ),
      );

      return const Right(null);
    } on Exception catch (e) {
      return Left(ValidationFailure('Failed to update validation: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> addPhotoToValidation({
    required String validationId,
    required String localPath,
  }) async {
    try {
      const uuid = Uuid();
      final photoId = uuid.v4();

      await database.insertValidationPhoto(
        ValidationPhotosCompanion(
          id: Value(photoId),
          validationId: Value(validationId),
          localPath: Value(localPath),
          fileName: Value(localPath.split('/').last),
          syncStatus: Value('pending'),
          createdAt: Value(DateTime.now()),
        ),
      );

      // Add to sync queue
      await syncQueueManager.addToQueue(
        entityType: 'photo',
        entityId: photoId,
        operation: 'create',
        payload: {
          'validation_id': validationId,
          'local_path': localPath,
        },
      );

      return const Right(null);
    } on Exception catch (e) {
      return Left(ValidationFailure('Failed to add photo: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> uploadValidation({
    required String validationId,
  }) async {
    try {
      final validation = await database.getValidationById(validationId);
      if (validation == null) {
        return Left(ValidationFailure('Validation not found'));
      }

      // Get photos
      final photos =
          await database.getPhotosByValidationId(validationId);
      final photoPaths = photos
          .map((p) => p.localPath)
          .toList();

      // Create request and upload
      final request = CreateValidationRequest(
        parcelId: validation.parcelId,
        status: validation.status,
        remarks: validation.remarks,
        latitude: validation.latitude,
        longitude: validation.longitude,
      );

      await apiService.uploadValidation(
        validation: request,
        photoPaths: photoPaths.isNotEmpty ? photoPaths : null,
      );

      // Mark as synced
      await database.updateValidationSyncStatus(validationId, 'synced');

      // Mark photos as synced
      for (final photo in photos) {
        await database.updatePhotoSyncStatus(photo.id, 'synced');
      }

      return const Right(null);
    } on Exception catch (e) {
      return Left(SyncFailure('Failed to upload validation: ${e.toString()}'));
    }
  }
}
