import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failures.dart';
import '../domain/validation_models.dart';

/// Repository contract for validation operations
abstract class ValidationRepository {
  /// Create a new validation
  Future<Either<Failure, ValidationEntity>> createValidation({
    required CreateValidationRequest request,
  });

  /// Get validation by ID
  Future<Either<Failure, ValidationEntity>> getValidationById({
    required String validationId,
  });

  /// Get validations for a parcel
  Future<Either<Failure, List<ValidationEntity>>> getValidationsByParcelId({
    required String parcelId,
  });

  /// Get pending validations (not yet synced)
  Future<Either<Failure, List<ValidationEntity>>> getPendingValidations();

  /// Update validation
  Future<Either<Failure, void>> updateValidation({
    required ValidationEntity validation,
  });

  /// Add photo to validation
  Future<Either<Failure, void>> addPhotoToValidation({
    required String validationId,
    required String localPath,
  });

  /// Upload validation to server
  Future<Either<Failure, void>> uploadValidation({
    required String validationId,
  });
}
