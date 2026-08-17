import 'package:latlong2/latlong.dart';

import 'travel_mode.dart';

/// A calculated route from an origin to a destination
class NavigationRoute {
  final List<LatLng> points;
  final double distanceMeters;
  final Duration duration;
  final TravelMode travelMode;
  final LatLng origin;
  final LatLng destination;
  final DateTime calculatedAt;

  NavigationRoute({
    required this.points,
    required this.distanceMeters,
    required this.duration,
    required this.travelMode,
    required this.origin,
    required this.destination,
    required this.calculatedAt,
  });

  String get formattedDistance {
    if (distanceMeters < 1000) return '${distanceMeters.round()} m';
    return '${(distanceMeters / 1000).toStringAsFixed(2)} km';
  }

  String get formattedDuration {
    final minutes = duration.inMinutes;
    if (minutes < 1) return '<1 min';
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    return '${hours}h ${remaining}min';
  }

  Map<String, dynamic> toJson() => {
    'points': points.map((p) => [p.latitude, p.longitude]).toList(),
    'distanceMeters': distanceMeters,
    'durationSeconds': duration.inSeconds,
    'travelMode': travelMode.name,
    'origin': [origin.latitude, origin.longitude],
    'destination': [destination.latitude, destination.longitude],
    'calculatedAt': calculatedAt.toIso8601String(),
  };

  factory NavigationRoute.fromJson(Map<String, dynamic> json) {
    LatLng pointFrom(dynamic pair) {
      final list = pair as List<dynamic>;
      return LatLng((list[0] as num).toDouble(), (list[1] as num).toDouble());
    }

    return NavigationRoute(
      points: (json['points'] as List<dynamic>).map(pointFrom).toList(),
      distanceMeters: (json['distanceMeters'] as num).toDouble(),
      duration: Duration(seconds: json['durationSeconds'] as int),
      travelMode: TravelMode.values.firstWhere(
        (mode) => mode.name == json['travelMode'],
        orElse: () => TravelMode.walking,
      ),
      origin: pointFrom(json['origin']),
      destination: pointFrom(json['destination']),
      calculatedAt: DateTime.parse(json['calculatedAt'] as String),
    );
  }
}

/// Where a resolved parcel access point came from
enum AccessPointSource { mapxDefined, nearestRoad, centroid }

/// The resolved navigation target for a parcel
class ParcelAccessPoint {
  final LatLng point;
  final AccessPointSource source;

  ParcelAccessPoint({required this.point, required this.source});

  String get label {
    switch (source) {
      case AccessPointSource.mapxDefined:
        return 'MapX access point';
      case AccessPointSource.nearestRoad:
        return 'Nearest road';
      case AccessPointSource.centroid:
        return 'Parcel center';
    }
  }
}
