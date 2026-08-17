import 'package:latlong2/latlong.dart';
import 'dart:math' as math;

/// Information about a route between two points
class RouteInfo {
  final List<LatLng> points;
  final double distanceMeters;
  final Duration estimatedDuration;

  RouteInfo({
    required this.points,
    required this.distanceMeters,
    required this.estimatedDuration,
  });

  /// Get formatted distance string
  String get formattedDistance {
    if (distanceMeters < 1000) {
      return '${distanceMeters.toStringAsFixed(0)}m';
    }
    return '${(distanceMeters / 1000).toStringAsFixed(2)}km';
  }

  /// Get formatted ETA
  String get formattedETA {
    final minutes = estimatedDuration.inMinutes;
    if (minutes < 60) {
      return '${minutes}min';
    }
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '${hours}h ${remainingMinutes}min';
  }
}

/// Abstract service for map operations
abstract class MapService {
  /// Get route between two points
  Future<RouteInfo?> getRoute({
    required LatLng origin,
    required LatLng destination,
  });

  /// Check if location is within bounds
  bool isLocationInBounds({
    required LatLng location,
    required List<LatLng> bounds,
  });

  /// Calculate bearing between two points
  double calculateBearing({
    required LatLng from,
    required LatLng to,
  });
}

/// Implementation using OSRM (Open Source Routing Machine)
class OSRMMapService implements MapService {
  static const String _osrmBaseUrl = 'https://router.project-osrm.org';

  OSRMMapService();

  @override
  Future<RouteInfo?> getRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      // OSRM API: GET /route/v1/driving/{lon1},{lat1};{lon2},{lat2}
      // final url =
      //     '$_osrmBaseUrl/route/v1/driving/${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}?overview=full&geometries=geojson';

      // This would typically use a HTTP client (Dio)
      // For now, returning null as placeholder
      // In real implementation, fetch from OSRM API and parse response

      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  bool isLocationInBounds({
    required LatLng location,
    required List<LatLng> bounds,
  }) {
    // Simple point-in-polygon check (simplified)
    // For production, use a proper algorithm like ray casting
    if (bounds.isEmpty) return false;

    bool inside = false;
    int j = bounds.length - 1;

    for (int i = 0; i < bounds.length; i++) {
      final xi = bounds[i].latitude;
      final yi = bounds[i].longitude;
      final xj = bounds[j].latitude;
      final yj = bounds[j].longitude;

      final intersect = (yi > location.longitude) !=
              (yj > location.longitude) &&
          (location.latitude) < (xj - xi) * (location.longitude - yi) / (yj - yi) + xi;

      if (intersect) inside = !inside;
      j = i;
    }

    return inside;
  }

  @override
  double calculateBearing({
    required LatLng from,
    required LatLng to,
  }) {
    final dLon = to.longitude - from.longitude;
    final y = math.sin(dLon * math.pi / 180) * math.cos(to.latitude * math.pi / 180);
    final x = math.cos(from.latitude * math.pi / 180) * math.sin(to.latitude * math.pi / 180) -
        math.sin(from.latitude * math.pi / 180) * math.cos(to.latitude * math.pi / 180) * math.cos(dLon * math.pi / 180);
    final bearing = math.atan2(y, x);
    return (bearing * 180 / math.pi + 360) % 360;
  }
}

/// Utility functions for geographic calculations are now using dart:math
