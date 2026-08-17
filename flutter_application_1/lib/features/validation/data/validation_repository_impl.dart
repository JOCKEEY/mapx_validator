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

  ValidationEntity _entityFrom(Validation validation, List<ValidationPhoto> photos) {
    return ValidationEntity(
      id: validation.id,
      parcelId: validation.parcelId,
      tdNumber: validation.tdNumber,
      status: validation.status,
      remarks: validation.remarks,
      latitude: validation.latitude,
      longitude: validation.longitude,
      createdAt: validation.createdAt,
      syncStatus: validation.syncStatus,
      photoIds: photos.map((p) => p.id).toList(),
      photoPaths: photos.map((p) => p.localPath).toList(),
    );
  }

  @override
  Future<Either<Failure, ValidationEntity>> createValidation({
    required CreateValidationRequest request,
  }) async {
    try {
      const uuid = Uuid();
      final validationId = uuid.v4();
      final now = DateTime.now();

      // Save to database
      await database.insertValidation(
        ValidationsCompanion(
          id: Value(validationId),
          parcelId: Value(request.parcelId),
          tdNumber: Value(request.tdNumber),
          status: Value(request.status),
          remarks: Value(request.remarks),
          latitude: Value(request.latitude),
          longitude: Value(request.longitude),
          syncStatus: const Value('pending'),
          createdAt: Value(now),
          updatedAt: Value(now),
          retryCount: const Value(0),
        ),
      );

      // Track in the generic sync queue too, for future sync-status tooling
      await syncQueueManager.addToQueue(
        entityType: 'validation',
        entityId: validationId,
        operation: 'create',
        payload: request.toJson(),
      );

      return Right(
        ValidationEntity(
          id: validationId,
          parcelId: request.parcelId,
          tdNumber: request.tdNumber,
          status: request.status,
          remarks: request.remarks,
          latitude: request.latitude,
          longitude: request.longitude,
          createdAt: now,
          photoIds: [],
        ),
      );
    } on Exception catch (e) {
      return Left(ValidationFailure(_messageOf(e)));
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

      final photos = await database.getPhotosByValidationId(validationId);
      return Right(_entityFrom(validation, photos));
    } on Exception catch (e) {
      return Left(ValidationFailure(_messageOf(e)));
    }
  }

  @override
  Future<Either<Failure, List<ValidationEntity>>> getValidationsByParcelId({
    required String parcelId,
  }) async {
    try {
      final validations = await database.getValidationsByParcelId(parcelId);

      final entities = <ValidationEntity>[];
      for (final validation in validations) {
        final photos = await database.getPhotosByValidationId(validation.id);
        entities.add(_entityFrom(validation, photos));
      }

      return Right(entities);
    } on Exception catch (e) {
      return Left(ValidationFailure(_messageOf(e)));
    }
  }

  @override
  Future<Either<Failure, ValidationEntity?>> getLatestValidationForParcel({
    required String parcelId,
  }) async {
    try {
      final validations = await database.getValidationsByParcelId(parcelId);
      if (validations.isEmpty) return const Right(null);

      // Already ordered most-recent-first by the DAO
      final latest = validations.first;
      final photos = await database.getPhotosByValidationId(latest.id);
      return Right(_entityFrom(latest, photos));
    } on Exception catch (e) {
      return Left(ValidationFailure(_messageOf(e)));
    }
  }

  @override
  Future<Either<Failure, List<ValidationEntity>>> getPendingValidations() async {
    try {
      final validations = await database.getPendingValidations();

      final entities = <ValidationEntity>[];
      for (final validation in validations) {
        final photos = await database.getPhotosByValidationId(validation.id);
        entities.add(_entityFrom(validation, photos));
      }

      return Right(entities);
    } on Exception catch (e) {
      return Left(ValidationFailure(_messageOf(e)));
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
          tdNumber: Value(validation.tdNumber),
          status: Value(validation.status),
          remarks: Value(validation.remarks),
          latitude: Value(validation.latitude),
          longitude: Value(validation.longitude),
          updatedAt: Value(DateTime.now()),
        ),
      );

      return const Right(null);
    } on Exception catch (e) {
      return Left(ValidationFailure(_messageOf(e)));
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
          syncStatus: const Value('pending'),
          createdAt: Value(DateTime.now()),
        ),
      );

      return const Right(null);
    } on Exception catch (e) {
      return Left(ValidationFailure(_messageOf(e)));
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

      final photos = await database.getPhotosByValidationId(validationId);
      final photoPaths = photos.map((p) => p.localPath).toList();

      await apiService.createRpuLandValidation(
        validation: CreateValidationRequest(
          parcelId: validation.parcelId,
          tdNumber: validation.tdNumber,
          status: validation.status,
          remarks: validation.remarks,
          latitude: validation.latitude,
          longitude: validation.longitude,
          surveyDate: validation.createdAt,
        ),
        photoPaths: photoPaths.isNotEmpty ? photoPaths : null,
      );

      await database.markValidationSynced(validationId);
      for (final photo in photos) {
        await database.updatePhotoSyncStatus(photo.id, 'synced');
      }

      return const Right(null);
    } on Exception catch (e) {
      return Left(SyncFailure(_messageOf(e)));
    }
  }

  @override
  Future<int> syncPendingValidations() async {
    final pending = await database.getPendingValidations();

    var succeeded = 0;
    for (final validation in pending) {
      final result = await uploadValidation(validationId: validation.id);
      if (result.isRight()) succeeded++;
    }
    return succeeded;
  }

  /// Strips the `Exception: ` prefix Dart adds to `Exception(message).toString()`
  String _messageOf(Exception e) => e.toString().replaceFirst('Exception: ', '');
}
