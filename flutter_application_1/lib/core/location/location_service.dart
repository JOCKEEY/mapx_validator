import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../constants/app_constants.dart';
import '../errors/failures.dart';

/// Service for handling GPS location tracking and permissions
class LocationService {
  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Request location permission
  Future<bool> requestLocationPermission() async {
    final permission = Permission.location;

    if (await permission.isDenied) {
      final result = await permission.request();
      return result.isGranted;
    } else if (await permission.isDenied) {
      return false;
    } else if (await permission.isPermanentlyDenied) {
      openAppSettings();
      return false;
    }

    return true;
  }

  /// Check location permission status
  Future<bool> hasLocationPermission() async {
    final permission = Permission.location;
    final status = await permission.status;
    return status.isGranted;
  }

  /// Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      // Check if location service is enabled
      final isEnabled = await isLocationServiceEnabled();
      if (!isEnabled) {
        throw LocationFailure.locationServiceDisabled();
      }

      // Request permission if needed
      final hasPermission = await hasLocationPermission();
      if (!hasPermission) {
        final granted = await requestLocationPermission();
        if (!granted) {
          throw LocationFailure.permissionDenied();
        }
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: LocationConstants.minDistanceFilter.toInt(),
        ),
      );

      return position;
    } on LocationFailure {
      rethrow;
    } catch (e) {
      throw LocationFailure.failedToObtainLocation();
    }
  }

  /// Stream of location updates
  Stream<Position> getLocationUpdates({
    LocationAccuracy accuracy = LocationAccuracy.best,
    int? distanceFilter,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter ?? LocationConstants.minDistanceFilter.toInt(),
      ),
    );
  }

  /// Calculate distance between two coordinates (in meters)
  Future<double> getDistanceBetween({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) async {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Check if user has arrived at destination (within threshold)
  Future<bool> hasArrivedAtDestination({
    required double currentLat,
    required double currentLng,
    required double targetLat,
    required double targetLng,
    double thresholdMeters = LocationConstants.parcelArrivalThreshold,
  }) async {
    final distance = await getDistanceBetween(
      startLatitude: currentLat,
      startLongitude: currentLng,
      endLatitude: targetLat,
      endLongitude: targetLng,
    );

    return distance <= thresholdMeters;
  }

  /// Open app settings for location permission
  void openAppSettings() {
    openAppSettings();
  }
}
