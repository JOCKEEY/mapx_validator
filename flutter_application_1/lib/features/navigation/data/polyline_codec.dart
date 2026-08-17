import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// Decodes a Valhalla-style encoded polyline into LatLng points.
/// Valhalla uses 6 decimal places of precision (unlike Google's 5).
List<LatLng> decodePolyline(String encoded, {int precision = 6}) {
  final factor = math.pow(10, precision).toDouble();
  final points = <LatLng>[];
  var index = 0;
  var lat = 0;
  var lng = 0;

  int readDelta() {
    var shift = 0;
    var result = 0;
    int byte;
    do {
      byte = encoded.codeUnitAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);
    return (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
  }

  while (index < encoded.length) {
    lat += readDelta();
    lng += readDelta();
    points.add(LatLng(lat / factor, lng / factor));
  }

  return points;
}
