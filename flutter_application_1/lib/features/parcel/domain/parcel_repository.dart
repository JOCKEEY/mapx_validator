import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failures.dart';
import 'parcel_models.dart';

/// Repository contract for land parcel operations
abstract class ParcelRepository {
  /// Search land parcels by PIN or TD Number (comma-separated for multiple)
  Future<Either<Failure, List<LandParcel>>> searchLand(String query);

  /// Save a parcel locally to validate later
  Future<Either<Failure, void>> addToQueue(LandParcel parcel);

  /// Remove a parcel from the local validation queue
  Future<Either<Failure, void>> removeFromQueue(String parcelId);

  /// Get all parcels currently queued for validation
  Future<Either<Failure, List<LandParcel>>> getQueuedParcels();
}
