/// Simple validation models without Freezed
/// TODO: Migrate back to Freezed once code generation works properly

/// Validation DTO
class ValidationDto {
  final String id;
  final String parcelId;
  final String status;
  final String? remarks;
  final double latitude;
  final double longitude;
  final DateTime createdAt;

  ValidationDto({
    required this.id,
    required this.parcelId,
    required this.status,
    this.remarks,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'parcelId': parcelId,
    'status': status,
    'remarks': remarks,
    'latitude': latitude,
    'longitude': longitude,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ValidationDto.fromJson(Map<String, dynamic> json) =>
      ValidationDto(
        id: json['id'] as String,
        parcelId: json['parcelId'] as String,
        status: json['status'] as String,
        remarks: json['remarks'] as String?,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

/// Validation domain entity
class ValidationEntity {
  final String id;
  final String parcelId;
  final String status;
  final String? remarks;
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final List<String> photoIds;

  ValidationEntity({
    required this.id,
    required this.parcelId,
    required this.status,
    this.remarks,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    required this.photoIds,
  });

  factory ValidationEntity.fromDto(ValidationDto dto, List<String> photoIds) {
    return ValidationEntity(
      id: dto.id,
      parcelId: dto.parcelId,
      status: dto.status,
      remarks: dto.remarks,
      latitude: dto.latitude,
      longitude: dto.longitude,
      createdAt: dto.createdAt,
      photoIds: photoIds,
    );
  }

  ValidationDto toDto() => ValidationDto(
    id: id,
    parcelId: parcelId,
    status: status,
    remarks: remarks,
    latitude: latitude,
    longitude: longitude,
    createdAt: createdAt,
  );
}

/// Photo entity
class PhotoEntity {
  final String id;
  final String validationId;
  final String localPath;
  final String? remotePath;
  final String syncStatus;

  PhotoEntity({
    required this.id,
    required this.validationId,
    required this.localPath,
    this.remotePath,
    required this.syncStatus,
  });
}

/// Validation creation request
class CreateValidationRequest {
  final String parcelId;
  final String status;
  final String? remarks;
  final double latitude;
  final double longitude;

  CreateValidationRequest({
    required this.parcelId,
    required this.status,
    this.remarks,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() => {
    'parcelId': parcelId,
    'status': status,
    'remarks': remarks,
    'latitude': latitude,
    'longitude': longitude,
  };

  factory CreateValidationRequest.fromJson(Map<String, dynamic> json) =>
      CreateValidationRequest(
        parcelId: json['parcelId'] as String,
        status: json['status'] as String,
        remarks: json['remarks'] as String?,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
      );
}
