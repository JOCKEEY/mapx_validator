import 'dart:convert';

import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../parcel/domain/parcel_models.dart';
import '../domain/navigation_models.dart';

/// Caches the last-known GPS location, selected parcel, and calculated
/// route so navigation can gracefully fall back to "last known" state
/// when the device is offline.
class NavigationCacheService {
  final SecureStorageService secureStorage;

  NavigationCacheService({required this.secureStorage});

  Future<void> saveLastLocation(LatLng location) async {
    await secureStorage.savePref(
      StorageKeys.navLastLocation,
      jsonEncode({'lat': location.latitude, 'lon': location.longitude}),
    );
  }

  Future<LatLng?> getLastLocation() async {
    final raw = await secureStorage.getPref(StorageKeys.navLastLocation);
    if (raw == null) return null;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return LatLng(
      (map['lat'] as num).toDouble(),
      (map['lon'] as num).toDouble(),
    );
  }

  Future<void> saveSelectedParcel(LandParcel parcel) async {
    await secureStorage.savePref(
      StorageKeys.navSelectedParcel,
      jsonEncode(parcel.toJson()),
    );
  }

  Future<LandParcel?> getSelectedParcel() async {
    final raw = await secureStorage.getPref(StorageKeys.navSelectedParcel);
    if (raw == null) return null;
    return LandParcel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveLastRoute(NavigationRoute route) async {
    await secureStorage.savePref(
      StorageKeys.navLastRoute,
      jsonEncode(route.toJson()),
    );
  }

  Future<NavigationRoute?> getLastRoute() async {
    final raw = await secureStorage.getPref(StorageKeys.navLastRoute);
    if (raw == null) return null;
    return NavigationRoute.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> clear() async {
    await secureStorage.delete(StorageKeys.navLastLocation);
    await secureStorage.delete(StorageKeys.navSelectedParcel);
    await secureStorage.delete(StorageKeys.navLastRoute);
  }
}
