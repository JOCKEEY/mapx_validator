import '../../parcel/domain/parcel_models.dart';
import '../domain/navigation_models.dart';
import '../domain/parcel_routing_service.dart';
import '../domain/routing_service.dart';

/// Resolves the best navigation target for a parcel using
/// [RoutingService.snapToNearestRoad] for the road-snapping step, so the
/// full MapX-defined → nearest-road → centroid hierarchy is available
/// (and independently inspectable/testable) beyond the simpler fallback
/// baked into [RoutingService.calculateRouteToParcel].
class ParcelRoutingServiceImpl implements ParcelRoutingService {
  final RoutingService routingService;

  ParcelRoutingServiceImpl({required this.routingService});

  @override
  Future<ParcelAccessPoint> resolveAccessPoint(LandParcel parcel) async {
    // 1. MapX-defined access/navigation point, if the backend provided one
    final defined = parcel.accessPoint;
    if (defined != null) {
      return ParcelAccessPoint(
        point: defined,
        source: AccessPointSource.mapxDefined,
      );
    }

    final centroid = parcel.centroid;

    // 2. Nearest accessible road/path point to the parcel
    if (centroid != null) {
      try {
        final snapped = await routingService.snapToNearestRoad(centroid);
        if (snapped != null) {
          return ParcelAccessPoint(
            point: snapped,
            source: AccessPointSource.nearestRoad,
          );
        }
      } catch (_) {
        // Fall through to the centroid fallback below
      }
    }

    // 3. Polygon centroid, only as a last resort
    if (centroid != null) {
      return ParcelAccessPoint(
        point: centroid,
        source: AccessPointSource.centroid,
      );
    }

    throw StateError('Parcel ${parcel.id} has no geometry to navigate to');
  }
}
