import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_constants.dart';
import '../../parcel/domain/parcel_models.dart';
import '../domain/navigation_models.dart';
import '../domain/routing_service.dart';
import '../domain/travel_mode.dart';
import 'polyline_codec.dart';

/// [RoutingService] backed by a Valhalla routing engine. Talks to whatever
/// host `dio` is configured with — point it at a self-hosted or offline
/// Valhalla instance to remove the dependency on the public demo server.
class ValhallaRoutingService implements RoutingService {
  final Dio dio;

  ValhallaRoutingService({required this.dio});

  @override
  Future<NavigationRoute> calculateRoute({
    required LatLng origin,
    required LatLng destination,
    required TravelMode travelMode,
  }) async {
    late final Response response;
    try {
      response = await dio.post(
        RoutingConstants.routeEndpoint,
        data: {
          'locations': [
            {'lat': origin.latitude, 'lon': origin.longitude},
            {'lat': destination.latitude, 'lon': destination.longitude},
          ],
          'costing': travelMode.valhallaCosting,
          'units': 'kilometers',
        },
      );
    } on DioException catch (e) {
      throw Exception('Route request failed: ${e.message}');
    }

    if (response.statusCode != 200) {
      throw Exception(_extractErrorMessage(response));
    }

    final trip =
        (response.data as Map<String, dynamic>)['trip']
            as Map<String, dynamic>?;
    if (trip == null) {
      throw Exception('Route response was missing trip data');
    }

    final legs = trip['legs'] as List<dynamic>?;
    if (legs == null || legs.isEmpty) {
      throw Exception('Route response had no legs');
    }

    final points = <LatLng>[
      for (final leg in legs)
        ...decodePolyline(
          (leg as Map<String, dynamic>)['shape'] as String,
          precision: RoutingConstants.polylinePrecision,
        ),
    ];

    final summary = trip['summary'] as Map<String, dynamic>?;
    final lengthKm = (summary?['length'] as num?)?.toDouble() ?? 0.0;
    final timeSeconds = (summary?['time'] as num?)?.toInt() ?? 0;

    return NavigationRoute(
      points: points,
      distanceMeters: lengthKm * 1000,
      duration: Duration(seconds: timeSeconds),
      travelMode: travelMode,
      origin: origin,
      destination: destination,
      calculatedAt: DateTime.now(),
    );
  }

  @override
  Future<NavigationRoute> calculateRouteToParcel({
    required LatLng currentLocation,
    required LandParcel parcel,
    required TravelMode travelMode,
  }) async {
    var destination = parcel.accessPoint ?? parcel.centroid;
    if (destination == null) {
      throw Exception('Parcel ${parcel.id} has no geometry to navigate to');
    }

    if (parcel.accessPoint == null) {
      final snapped = await snapToNearestRoad(destination);
      if (snapped != null) destination = snapped;
    }

    return calculateRoute(
      origin: currentLocation,
      destination: destination,
      travelMode: travelMode,
    );
  }

  @override
  double getDistance(NavigationRoute route) => route.distanceMeters;

  @override
  Duration getEstimatedDuration(NavigationRoute route) => route.duration;

  @override
  Future<LatLng?> snapToNearestRoad(LatLng point) async {
    late final Response response;
    try {
      response = await dio.post(
        RoutingConstants.locateEndpoint,
        data: {
          'locations': [
            {'lat': point.latitude, 'lon': point.longitude},
          ],
          'costing': TravelMode.walking.valhallaCosting,
        },
      );
    } on DioException {
      return null;
    }

    if (response.statusCode != 200) return null;

    final results = response.data;
    if (results is! List || results.isEmpty) return null;

    final first = results.first;
    if (first is! Map<String, dynamic>) return null;

    final edges = first['edges'];
    if (edges is! List || edges.isEmpty) return null;

    final edge = edges.first;
    if (edge is! Map<String, dynamic>) return null;

    final lat = edge['correlated_lat'];
    final lon = edge['correlated_lon'];
    if (lat is num && lon is num) {
      return LatLng(lat.toDouble(), lon.toDouble());
    }
    return null;
  }

  /// Extract a human-readable error message from a failed response
  String _extractErrorMessage(Response response) {
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final message = data['error'] ?? data['error_description'];
      if (message != null) return message.toString();
    }
    return 'Route request failed with status ${response.statusCode}';
  }
}
