import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:fpdart/fpdart.dart';

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
  Future<Either<Failure, List<LandParcel>>> searchLand(String query) async {
    try {
      final results = await apiService.searchLand(query);
      return Right(results);
    } on Exception catch (e) {
      return Left(NetworkFailure(_messageOf(e)));
    }
  }

  @override
  Future<Either<Failure, void>> addToQueue(LandParcel parcel) async {
    try {
      await database.upsertRpuQueueItem(
        RpuQueueItemsCompanion(
          id: drift.Value(parcel.id),
          pin: drift.Value(parcel.pin),
          tdNumber: drift.Value(parcel.tdNumber),
          owner: drift.Value(parcel.owner),
          municipality: drift.Value(parcel.municipality),
          barangay: drift.Value(parcel.barangay),
          landClass: drift.Value(parcel.landClass),
          payloadJson: drift.Value(jsonEncode(parcel.toJson())),
          addedAt: drift.Value(DateTime.now()),
        ),
      );
      return const Right(null);
    } on Exception catch (e) {
      return Left(CacheFailure(_messageOf(e)));
    }
  }

  @override
  Future<Either<Failure, void>> removeFromQueue(String parcelId) async {
    try {
      await database.deleteRpuQueueItem(parcelId);
      return const Right(null);
    } on Exception catch (e) {
      return Left(CacheFailure(_messageOf(e)));
    }
  }

  @override
  Future<Either<Failure, List<LandParcel>>> getQueuedParcels() async {
    try {
      final rows = await database.getRpuQueueItems();
      final parcels = rows
          .map((row) =>
              LandParcel.fromJson(jsonDecode(row.payloadJson) as Map<String, dynamic>))
          .toList();
      return Right(parcels);
    } on Exception catch (e) {
      return Left(CacheFailure(_messageOf(e)));
    }
  }

  /// Strips the `Exception: ` prefix Dart adds to `Exception(message).toString()`
  String _messageOf(Exception e) =>
      e.toString().replaceFirst('Exception: ', '');
}
