/// Travel mode for route calculation, mapped to a Valhalla costing model
enum TravelMode {
  walking,
  driving,
  bicycle;

  /// Valhalla costing model name for this travel mode
  String get valhallaCosting {
    switch (this) {
      case TravelMode.walking:
        return 'pedestrian';
      case TravelMode.driving:
        return 'auto';
      case TravelMode.bicycle:
        return 'bicycle';
    }
  }

  String get label {
    switch (this) {
      case TravelMode.walking:
        return 'Walking';
      case TravelMode.driving:
        return 'Driving';
      case TravelMode.bicycle:
        return 'Bicycle';
    }
  }
}
