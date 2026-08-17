import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../core/constants/app_constants.dart';
import '../../core/database/app_database.dart';
import '../../core/network/dio_setup.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../core/location/location_service.dart';
import '../../core/sync/sync_queue_manager.dart';
import '../../features/auth/data/auth_api_service.dart';
import '../../features/auth/data/auth_repository_impl.dart';
import '../../features/auth/domain/auth_repository.dart';
import '../../features/auth/domain/auth_usecases.dart';
import '../../features/navigation/data/navigation_cache_service.dart';
import '../../features/navigation/data/parcel_routing_service_impl.dart';
import '../../features/navigation/data/valhalla_routing_service.dart';
import '../../features/navigation/domain/parcel_routing_service.dart';
import '../../features/navigation/domain/routing_service.dart';
import '../../features/parcel/data/parcel_api_service.dart';
import '../../features/parcel/data/parcel_repository_impl.dart';
import '../../features/parcel/domain/parcel_models.dart';
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
  return DioSetup.createDio(secureStorage: secureStorage);
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

/// Provider for the login use case
final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(repository: ref.watch(authRepositoryProvider));
});

/// Provider for the logout use case
final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(repository: ref.watch(authRepositoryProvider));
});

/// Provider for the change-password use case
final changePasswordUseCaseProvider = Provider<ChangePasswordUseCase>((ref) {
  return ChangePasswordUseCase(repository: ref.watch(authRepositoryProvider));
});

/// Provider for the get-stored-user use case
final getStoredUserUseCaseProvider = Provider<GetStoredUserUseCase>((ref) {
  return GetStoredUserUseCase(repository: ref.watch(authRepositoryProvider));
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

  return ParcelRepositoryImpl(apiService: apiService, database: database);
});

/// Live-updating list of land parcels queued locally for field validation
final rpuQueueProvider = StreamProvider<List<RpuQueueItem>>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return database.watchRpuQueueItems();
});

/// Queued land parcels decoded back into domain objects (owner, geometry,
/// PIN/TD number, etc.) for screens that need more than just the count
final rpuQueueParcelsProvider = Provider<List<LandParcel>>((ref) {
  final items = ref.watch(rpuQueueProvider).valueOrNull ?? [];
  return items
      .map(
        (item) => LandParcel.fromJson(
          jsonDecode(item.payloadJson) as Map<String, dynamic>,
        ),
      )
      .toList();
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

/// Live-updating list of all locally saved validations, most recent first
final validationsProvider = StreamProvider<List<Validation>>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return database.watchValidations();
});

/// The latest local validation per parcel id — used to show "already
/// validated, just needs to be sent" badges on parcel lists.
final validationsByParcelProvider = Provider<Map<String, Validation>>((ref) {
  final validations = ref.watch(validationsProvider).valueOrNull ?? [];
  final byParcel = <String, Validation>{};
  // validationsProvider is ordered most-recent-first, so the first entry
  // seen per parcel is the one to keep.
  for (final validation in validations) {
    byParcel.putIfAbsent(validation.parcelId, () => validation);
  }
  return byParcel;
});

/// Dio client dedicated to the routing engine (a different host than the
/// MapX API, with no auth token attached — kept separate from [dioProvider]
/// on purpose). Swap [RoutingConstants.valhallaBaseUrl] to point this at a
/// self-hosted or offline Valhalla instance.
final routingDioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl: RoutingConstants.valhallaBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      contentType: 'application/json',
    ),
  );
});

/// Provider for the routing engine (Valhalla by default)
final routingServiceProvider = Provider<RoutingService>((ref) {
  return ValhallaRoutingService(dio: ref.watch(routingDioProvider));
});

/// Provider for resolving a parcel's best navigation/access point
final parcelRoutingServiceProvider = Provider<ParcelRoutingService>((ref) {
  return ParcelRoutingServiceImpl(
    routingService: ref.watch(routingServiceProvider),
  );
});

/// Provider for the navigation offline cache (last location/parcel/route)
final navigationCacheServiceProvider = Provider<NavigationCacheService>((ref) {
  return NavigationCacheService(
    secureStorage: ref.watch(secureStorageProvider),
  );
});

/// Watches connectivity and, the moment the device comes back online,
/// automatically retries any validations that were saved locally while
/// offline. Read this once (e.g. via `ref.watch` at the app root) to
/// activate it — it does nothing until something keeps it alive.
final validationSyncCoordinatorProvider = Provider<void>((ref) {
  ref.listen<bool>(isOnlineProvider, (previous, isOnline) {
    if (isOnline && previous == false) {
      ref.read(validationRepositoryProvider).syncPendingValidations();
    }
  });
});
