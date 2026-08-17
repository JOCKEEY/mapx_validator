import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failures.dart';
import '../domain/parcel_models.dart';

/// Repository contract for parcel operations
abstract class ParcelRepository {
  /// Search parcels by query (PIN or TD Number)
  Future<Either<Failure, List<ParcelSearchResult>>> searchParcels({
    required String query,
  });

  /// Get detailed information for a parcel
  Future<Either<Failure, ParcelEntity>> getParcelById({
    required String parcelId,
  });

  /// Get cached parcels from local database
  Future<Either<Failure, List<ParcelEntity>>> getCachedParcels();

  /// Download parcels for offline access
  Future<Either<Failure, void>> downloadParcelsForBarangay({
    required String barangayId,
  });

  /// Cache search results locally
  Future<Either<Failure, void>> cacheParcel({
    required ParcelEntity parcel,
  });
}
