import 'package:latlong2/latlong.dart';

/// A land parcel returned by the validator land search
class LandParcel {
  final String id;
  final String? rpulandId;
  final String owner;
  final double? area;
  final String? octtcNumber;
  final String? arpNumber;
  final String? tdNumber;
  final String? surveyNumber;
  final String? landClass;
  final String? otherLandClass;
  final double? marketValue;
  final double? assessedValue;
  final String? lot;
  final bool isTaxExempted;
  final String? municipality;
  final String? barangay;
  final String pin;
  final Map<String, dynamic>? geometry;
  final String? assessorId;
  final String? createdBy;
  final String? code;
  final int? year;
  final LatLng? accessPoint;

  LandParcel({
    required this.id,
    this.rpulandId,
    required this.owner,
    this.area,
    this.octtcNumber,
    this.arpNumber,
    this.tdNumber,
    this.surveyNumber,
    this.landClass,
    this.otherLandClass,
    this.marketValue,
    this.assessedValue,
    this.lot,
    required this.isTaxExempted,
    this.municipality,
    this.barangay,
    required this.pin,
    this.geometry,
    this.assessorId,
    this.createdBy,
    this.code,
    this.year,
    this.accessPoint,
  });

  factory LandParcel.fromJson(Map<String, dynamic> json) => LandParcel(
    id: json['id'].toString(),
    rpulandId: json['rpulandId']?.toString(),
    owner: json['owner'] as String? ?? '',
    area: (json['area'] as num?)?.toDouble(),
    octtcNumber: json['octtcNumber'] as String?,
    arpNumber: json['arpNumber'] as String?,
    tdNumber: json['tdNumber'] as String?,
    surveyNumber: json['surveyNumber'] as String?,
    landClass: json['landClass'] as String?,
    otherLandClass: json['otherLandClass'] as String?,
    marketValue: (json['marketValue'] as num?)?.toDouble(),
    assessedValue: (json['assessedValue'] as num?)?.toDouble(),
    lot: json['lot'] as String?,
    isTaxExempted: json['isTaxExempted'] as bool? ?? false,
    municipality: json['municipality'] as String?,
    barangay: json['barangay'] as String?,
    pin: json['pin'] as String? ?? '',
    geometry: json['geometry'] as Map<String, dynamic>?,
    assessorId: json['assessorId']?.toString(),
    createdBy: json['createdBy'] as String?,
    code: json['code'] as String?,
    year: json['year'] as int?,
    accessPoint: _parseAccessPoint(json),
  );

  /// MapX doesn't yet document a dedicated field for this, so a few
  /// plausible shapes are checked defensively: a nested
  /// `accessPoint`/`navigationPoint` object with lat/lon-ish keys, or flat
  /// `accessLat`/`accessLon` fields. Returns null if none are present.
  static LatLng? _parseAccessPoint(Map<String, dynamic> json) {
    final nested = json['accessPoint'] ?? json['navigationPoint'];
    if (nested is Map<String, dynamic>) {
      final lat = nested['lat'] ?? nested['latitude'];
      final lon = nested['lon'] ?? nested['lng'] ?? nested['longitude'];
      if (lat is num && lon is num) {
        return LatLng(lat.toDouble(), lon.toDouble());
      }
    }

    final flatLat = json['accessLat'] ?? json['navLat'];
    final flatLon = json['accessLon'] ?? json['navLon'];
    if (flatLat is num && flatLon is num) {
      return LatLng(flatLat.toDouble(), flatLon.toDouble());
    }

    return null;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'rpulandId': rpulandId,
    'owner': owner,
    'area': area,
    'octtcNumber': octtcNumber,
    'arpNumber': arpNumber,
    'tdNumber': tdNumber,
    'surveyNumber': surveyNumber,
    'landClass': landClass,
    'otherLandClass': otherLandClass,
    'marketValue': marketValue,
    'assessedValue': assessedValue,
    'lot': lot,
    'isTaxExempted': isTaxExempted,
    'municipality': municipality,
    'barangay': barangay,
    'pin': pin,
    'geometry': geometry,
    'assessorId': assessorId,
    'createdBy': createdBy,
    'code': code,
    'year': year,
    if (accessPoint != null)
      'accessPoint': {
        'lat': accessPoint!.latitude,
        'lon': accessPoint!.longitude,
      },
  };

  /// Prefer the TD/ARP number as the primary label, falling back to the PIN
  String get identifierLabel {
    if (tdNumber != null && tdNumber!.isNotEmpty) return tdNumber!;
    return pin;
  }

  /// "Barangay, Municipality" location line, omitting empty parts
  String get locationLabel {
    final parts = [
      barangay,
      municipality,
    ].where((p) => p != null && p.isNotEmpty).toList();
    return parts.join(', ');
  }

  /// Exterior rings of this parcel's real geometry (GeoJSON Polygon or
  /// MultiPolygon), converted to LatLng for drawing on the map. Interior
  /// (hole) rings are ignored.
  List<List<LatLng>> get polygonRings {
    final geom = geometry;
    if (geom == null) return [];

    final type = geom['type'] as String?;
    final coordinates = geom['coordinates'];
    if (coordinates is! List) return [];

    List<LatLng> ringToLatLngs(dynamic ring) {
      final points = <LatLng>[];
      for (final position in ring as List<dynamic>) {
        final coords = position as List<dynamic>;
        final lng = (coords[0] as num).toDouble();
        final lat = (coords[1] as num).toDouble();
        points.add(LatLng(lat, lng));
      }
      return points;
    }

    // A Polygon's coordinates are a list of rings; a MultiPolygon's are a
    // list of polygons, each a list of rings. Only the first (exterior)
    // ring of each polygon is kept.
    if (type == 'MultiPolygon') {
      return [
        for (final polygon in coordinates)
          if ((polygon as List).isNotEmpty) ringToLatLngs(polygon.first),
      ];
    }
    if (type == 'Polygon' && coordinates.isNotEmpty) {
      return [ringToLatLngs(coordinates.first)];
    }
    return [];
  }

  /// Approximate center of this parcel's geometry, for map centering
  LatLng? get centroid {
    final rings = polygonRings;
    if (rings.isEmpty || rings.first.isEmpty) return null;

    final points = rings.first;
    var latSum = 0.0;
    var lngSum = 0.0;
    for (final point in points) {
      latSum += point.latitude;
      lngSum += point.longitude;
    }
    return LatLng(latSum / points.length, lngSum / points.length);
  }
}
