import 'package:latlong2/latlong.dart';

import '../../parcel/domain/parcel_models.dart';
import 'navigation_models.dart';
import 'travel_mode.dart';

/// Abstraction over a turn-by-turn routing engine (e.g. Valhalla).
///
/// Keeping this interface free of any engine-specific detail means the
/// backing implementation can later be swapped for a self-hosted or fully
/// offline routing engine without touching UI or state-management code.
abstract class RoutingService {
  /// Calculate a route between two points for the given travel mode
  Future<NavigationRoute> calculateRoute({
    required LatLng origin,
    required LatLng destination,
    required TravelMode travelMode,
  });

  /// Calculate a route from the current location to a parcel. Prefers the
  /// parcel's own access point if it has one, otherwise its centroid
  /// snapped to the nearest road.
  Future<NavigationRoute> calculateRouteToParcel({
    required LatLng currentLocation,
    required LandParcel parcel,
    required TravelMode travelMode,
  });

  double getDistance(NavigationRoute route);

  Duration getEstimatedDuration(NavigationRoute route);

  /// Snap a point to the nearest routable road/path, if the engine
  /// supports it. Returns null if no nearby road was found.
  Future<LatLng?> snapToNearestRoad(LatLng point);
}
