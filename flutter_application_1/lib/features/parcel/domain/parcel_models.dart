/// Simple parcel models without Freezed
/// TODO: Migrate back to Freezed once code generation works properly

import 'package:latlong2/latlong.dart';

/// Parcel DTO from API
class ParcelDto {
  final String id;
  final String pin;
  final String tdNumber;
  final String ownerName;
  final String? classification;
  final String? barangay;
  final String? municipality;
  final double? area;
  final String? geometryJson;
  final double? centroidLat;
  final double? centroidLng;

  ParcelDto({
    required this.id,
    required this.pin,
    required this.tdNumber,
    required this.ownerName,
    this.classification,
    this.barangay,
    this.municipality,
    this.area,
    this.geometryJson,
    this.centroidLat,
    this.centroidLng,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'pin': pin,
    'tdNumber': tdNumber,
    'ownerName': ownerName,
    'classification': classification,
    'barangay': barangay,
    'municipality': municipality,
    'area': area,
    'geometryJson': geometryJson,
    'centroidLat': centroidLat,
    'centroidLng': centroidLng,
  };

  factory ParcelDto.fromJson(Map<String, dynamic> json) => ParcelDto(
    id: json['id'] as String,
    pin: json['pin'] as String,
    tdNumber: json['tdNumber'] as String,
    ownerName: json['ownerName'] as String,
    classification: json['classification'] as String?,
    barangay: json['barangay'] as String?,
    municipality: json['municipality'] as String?,
    area: (json['area'] as num?)?.toDouble(),
    geometryJson: json['geometryJson'] as String?,
    centroidLat: (json['centroidLat'] as num?)?.toDouble(),
    centroidLng: (json['centroidLng'] as num?)?.toDouble(),
  );
}

/// Parcel domain entity
class ParcelEntity {
  final String id;
  final String pin;
  final String tdNumber;
  final String ownerName;
  final String? classification;
  final String? barangay;
  final String? municipality;
  final double? area;
  final String? geometryJson;
  final double? centroidLat;
  final double? centroidLng;

  ParcelEntity({
    required this.id,
    required this.pin,
    required this.tdNumber,
    required this.ownerName,
    this.classification,
    this.barangay,
    this.municipality,
    this.area,
    this.geometryJson,
    this.centroidLat,
    this.centroidLng,
  });

  factory ParcelEntity.fromDto(ParcelDto dto) {
    return ParcelEntity(
      id: dto.id,
      pin: dto.pin,
      tdNumber: dto.tdNumber,
      ownerName: dto.ownerName,
      classification: dto.classification,
      barangay: dto.barangay,
      municipality: dto.municipality,
      area: dto.area,
      geometryJson: dto.geometryJson,
      centroidLat: dto.centroidLat,
      centroidLng: dto.centroidLng,
    );
  }

  /// Get centroid as LatLng
  LatLng? get centroid {
    if (centroidLat != null && centroidLng != null) {
      return LatLng(centroidLat!, centroidLng!);
    }
    return null;
  }
}

/// Search result item
class ParcelSearchResult {
  final String id;
  final String pin;
  final String tdNumber;
  final String ownerName;

  ParcelSearchResult({
    required this.id,
    required this.pin,
    required this.tdNumber,
    required this.ownerName,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'pin': pin,
    'tdNumber': tdNumber,
    'ownerName': ownerName,
  };

  factory ParcelSearchResult.fromJson(Map<String, dynamic> json) =>
      ParcelSearchResult(
        id: json['id'] as String,
        pin: json['pin'] as String,
        tdNumber: json['tdNumber'] as String,
        ownerName: json['ownerName'] as String,
      );

  /// Convert to entity
  factory ParcelSearchResult.fromEntity(ParcelEntity entity) {
    return ParcelSearchResult(
      id: entity.id,
      pin: entity.pin,
      tdNumber: entity.tdNumber,
      ownerName: entity.ownerName,
    );
  }
}
