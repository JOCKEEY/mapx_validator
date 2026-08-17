import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../core/database/app_database.dart';
import '../../core/network/dio_setup.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../core/location/location_service.dart';
import '../../core/sync/sync_queue_manager.dart';
import '../../features/auth/data/auth_api_service.dart';
import '../../features/auth/data/auth_repository_impl.dart';
import '../../features/auth/domain/auth_repository.dart';
import '../../features/parcel/data/parcel_api_service.dart';
import '../../features/parcel/data/parcel_repository_impl.dart';
import '../../features/parcel/domain/parcel_repository.dart';
import '../../features/validation/data/validation_api_service.dart';
import '../../features/validation/data/validation_repository_impl.dart';
import '../../features/validation/domain/validation_repository.dart';

/// Provider for secure storage service
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

/// Provider for Dio client
final dioProvider = Provider<Dio>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return DioSetup.createDio(
    secureStorage: secureStorage,
  );
});

/// Provider for app database
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

/// Provider for location service
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// Provider for sync queue manager
final syncQueueManagerProvider = Provider<SyncQueueManager>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return SyncQueueManager(database: database);
});

/// Provider for connectivity status
final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

/// Provider for checking if app is online
final isOnlineProvider = Provider<bool>((ref) {
  final connectivity = ref.watch(connectivityProvider);

  return connectivity.maybeWhen(
    data: (results) => !results.contains(ConnectivityResult.none),
    orElse: () => false,
  );
});

/// Provider for auth API service
final authApiServiceProvider = Provider<AuthApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthApiService(dio: dio);
});

/// Provider for auth repository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiService = ref.watch(authApiServiceProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  final database = ref.watch(appDatabaseProvider);

  return AuthRepositoryImpl(
    apiService: apiService,
    secureStorage: secureStorage,
    database: database,
  );
});

/// Provider for parcel API service
final parcelApiServiceProvider = Provider<ParcelApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return ParcelApiService(dio: dio);
});

/// Provider for parcel repository
final parcelRepositoryProvider = Provider<ParcelRepository>((ref) {
  final apiService = ref.watch(parcelApiServiceProvider);
  final database = ref.watch(appDatabaseProvider);

  return ParcelRepositoryImpl(
    apiService: apiService,
    database: database,
  );
});

/// Provider for validation API service
final validationApiServiceProvider = Provider<ValidationApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return ValidationApiService(dio: dio);
});

/// Provider for validation repository
final validationRepositoryProvider = Provider<ValidationRepository>((ref) {
  final apiService = ref.watch(validationApiServiceProvider);
  final database = ref.watch(appDatabaseProvider);
  final syncQueueManager = ref.watch(syncQueueManagerProvider);

  return ValidationRepositoryImpl(
    apiService: apiService,
    database: database,
    syncQueueManager: syncQueueManager,
  );
});
