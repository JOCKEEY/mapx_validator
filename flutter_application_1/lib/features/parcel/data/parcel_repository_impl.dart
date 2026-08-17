import 'package:fpdart/fpdart.dart';
import 'package:drift/drift.dart' as drift;

import '../../../core/database/app_database.dart';
import '../../../core/errors/failures.dart';
import '../domain/parcel_models.dart';
import '../domain/parcel_repository.dart';
import 'parcel_api_service.dart';

/// Implementation of ParcelRepository
class ParcelRepositoryImpl implements ParcelRepository {
  final ParcelApiService apiService;
  final AppDatabase database;

  ParcelRepositoryImpl({
    required this.apiService,
    required this.database,
  });

  @override
  Future<Either<Failure, List<ParcelSearchResult>>> searchParcels({
    required String query,
  }) async {
    try {
      // Try local database first
      final localParcels = await database.searchParcels(query);
      if (localParcels.isNotEmpty) {
        return Right(
          localParcels
              .map((p) => ParcelSearchResult(
                    id: p.id,
                    pin: p.pin,
                    tdNumber: p.tdNumber,
                    ownerName: p.ownerName,
                  ))
              .toList(),
        );
      }

      // Fallback to API if nothing in cache
      final results = await apiService.searchParcels(query);

      // Cache results in database
      for (final result in results) {
        await database.upsertParcel(
          ParcelsCompanion(
            id: drift.Value(result.id),
            pin: drift.Value(result.pin),
            tdNumber: drift.Value(result.tdNumber),
            ownerName: drift.Value(result.ownerName),
            updatedAt: drift.Value(DateTime.now()),
          ),
        );
      }

      return Right(results);
    } on Exception catch (e) {
      return Left(NetworkFailure('Failed to search parcels: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, ParcelEntity>> getParcelById({
    required String parcelId,
  }) async {
    try {
      // Try local database first
      final localParcel = await database.getParcelById(parcelId);
      if (localParcel != null) {
        return Right(
          ParcelEntity(
            id: localParcel.id,
            pin: localParcel.pin,
            tdNumber: localParcel.tdNumber,
            ownerName: localParcel.ownerName,
            classification: localParcel.classification,
            barangay: localParcel.barangay,
            municipality: localParcel.municipality,
            area: localParcel.area,
            geometryJson: localParcel.geometryJson,
            centroidLat: localParcel.centroidLat,
            centroidLng: localParcel.centroidLng,
          ),
        );
      }

      // Fetch from API
      final dto = await apiService.getParcelDetails(parcelId);
      final entity = ParcelEntity.fromDto(dto);

      // Cache in database
      await database.upsertParcel(
        ParcelsCompanion(
          id: drift.Value(entity.id),
          pin: drift.Value(entity.pin),
          tdNumber: drift.Value(entity.tdNumber),
          ownerName: drift.Value(entity.ownerName),
          classification: drift.Value(entity.classification),
          barangay: drift.Value(entity.barangay),
          municipality: drift.Value(entity.municipality),
          area: drift.Value(entity.area),
          geometryJson: drift.Value(entity.geometryJson),
          centroidLat: drift.Value(entity.centroidLat),
          centroidLng: drift.Value(entity.centroidLng),
          updatedAt: drift.Value(DateTime.now()),
        ),
      );

      return Right(entity);
    } on Exception catch (e) {
      return Left(NetworkFailure('Failed to get parcel details: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<ParcelEntity>>> getCachedParcels() async {
    try {
      final parcels = await database.getAllParcels();
      return Right(
        parcels
            .map((p) => ParcelEntity(
                  id: p.id,
                  pin: p.pin,
                  tdNumber: p.tdNumber,
                  ownerName: p.ownerName,
                  classification: p.classification,
                  barangay: p.barangay,
                  municipality: p.municipality,
                  area: p.area,
                  geometryJson: p.geometryJson,
                  centroidLat: p.centroidLat,
                  centroidLng: p.centroidLng,
                ))
            .toList(),
      );
    } on Exception catch (e) {
      return Left(CacheFailure('Failed to get cached parcels: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> downloadParcelsForBarangay({
    required String barangayId,
  }) async {
    try {
      final dtos = await apiService.downloadParcelsForBarangay(barangayId);

      // Store in database
      for (final dto in dtos) {
        await database.upsertParcel(
          ParcelsCompanion(
            id: drift.Value(dto.id),
            pin: drift.Value(dto.pin),
            tdNumber: drift.Value(dto.tdNumber),
            ownerName: drift.Value(dto.ownerName),
            classification: drift.Value(dto.classification),
            barangay: drift.Value(dto.barangay),
            municipality: drift.Value(dto.municipality),
            area: drift.Value(dto.area),
            geometryJson: drift.Value(dto.geometryJson),
            centroidLat: drift.Value(dto.centroidLat),
            centroidLng: drift.Value(dto.centroidLng),
            downloadedAt: drift.Value(DateTime.now()),
            updatedAt: drift.Value(DateTime.now()),
          ),
        );
      }

      return const Right(null);
    } on Exception catch (e) {
      return Left(NetworkFailure('Failed to download parcels: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> cacheParcel({
    required ParcelEntity parcel,
  }) async {
    try {
      await database.upsertParcel(
        ParcelsCompanion(
          id: drift.Value(parcel.id),
          pin: drift.Value(parcel.pin),
          tdNumber: drift.Value(parcel.tdNumber),
          ownerName: drift.Value(parcel.ownerName),
          classification: drift.Value(parcel.classification),
          barangay: drift.Value(parcel.barangay),
          municipality: drift.Value(parcel.municipality),
          area: drift.Value(parcel.area),
          geometryJson: drift.Value(parcel.geometryJson),
          centroidLat: drift.Value(parcel.centroidLat),
          centroidLng: drift.Value(parcel.centroidLng),
          updatedAt: drift.Value(DateTime.now()),
        ),
      );
      return const Right(null);
    } on Exception catch (e) {
      return Left(CacheFailure('Failed to cache parcel: ${e.toString()}'));
    }
  }
}
