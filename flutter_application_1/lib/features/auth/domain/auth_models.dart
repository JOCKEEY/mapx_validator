/// Login response from POST /api/v1/rpuvalidator/login-app-user
class LoginResponseDto {
  final int id;
  final String emailAddress;
  final String fullName;
  final String token;
  final String emailStatus;
  final bool isSuperAdmin;
  final bool isInActive;
  final bool isPremiumAccount;
  final bool isRPUEncoder;
  final bool isMiscEncoder;
  final bool isSMVEncoder;
  final bool isBiller;
  final bool isFAASEncoder;
  final bool isMapViewer;
  final bool isRPURequestManager;
  final bool isRPUValidator;
  final bool isFAASValidator;
  final bool isMapDataManager;
  final bool rpuOwner;
  final String? region;
  final String? province;
  final String? municipality;
  final List<String> municipalityAccess;
  final List<String> restrictedRpuFields;

  LoginResponseDto({
    required this.id,
    required this.emailAddress,
    required this.fullName,
    required this.token,
    required this.emailStatus,
    required this.isSuperAdmin,
    required this.isInActive,
    required this.isPremiumAccount,
    required this.isRPUEncoder,
    required this.isMiscEncoder,
    required this.isSMVEncoder,
    required this.isBiller,
    required this.isFAASEncoder,
    required this.isMapViewer,
    required this.isRPURequestManager,
    required this.isRPUValidator,
    required this.isFAASValidator,
    required this.isMapDataManager,
    required this.rpuOwner,
    this.region,
    this.province,
    this.municipality,
    required this.municipalityAccess,
    required this.restrictedRpuFields,
  });

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) {
    return LoginResponseDto(
      id: json['id'] as int,
      emailAddress: json['emailAddress'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      token: json['token'] as String,
      emailStatus: json['emailStatus'] as String? ?? '',
      isSuperAdmin: json['isSuperAdmin'] as bool? ?? false,
      isInActive: json['isInActive'] as bool? ?? false,
      isPremiumAccount: json['isPremiumAccount'] as bool? ?? false,
      isRPUEncoder: json['isRPUEncoder'] as bool? ?? false,
      isMiscEncoder: json['isMiscEncoder'] as bool? ?? false,
      isSMVEncoder: json['isSMVEncoder'] as bool? ?? false,
      isBiller: json['isBiller'] as bool? ?? false,
      isFAASEncoder: json['isFAASEncoder'] as bool? ?? false,
      isMapViewer: json['isMapViewer'] as bool? ?? false,
      isRPURequestManager: json['isRPURequestManager'] as bool? ?? false,
      isRPUValidator: json['isRPUValidator'] as bool? ?? false,
      isFAASValidator: json['isFAASValidator'] as bool? ?? false,
      isMapDataManager: json['isMapDataManager'] as bool? ?? false,
      rpuOwner: json['rpuOwner'] as bool? ?? false,
      region: json['region'] as String?,
      province: json['province'] as String?,
      municipality: json['municipality'] as String?,
      municipalityAccess: (json['municipalityAccess'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      restrictedRpuFields:
          (json['restrictedRpuFields'] as List<dynamic>? ?? [])
              .map((e) => e.toString())
              .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'emailAddress': emailAddress,
        'fullName': fullName,
        'token': token,
        'emailStatus': emailStatus,
        'isSuperAdmin': isSuperAdmin,
        'isInActive': isInActive,
        'isPremiumAccount': isPremiumAccount,
        'isRPUEncoder': isRPUEncoder,
        'isMiscEncoder': isMiscEncoder,
        'isSMVEncoder': isSMVEncoder,
        'isBiller': isBiller,
        'isFAASEncoder': isFAASEncoder,
        'isMapViewer': isMapViewer,
        'isRPURequestManager': isRPURequestManager,
        'isRPUValidator': isRPUValidator,
        'isFAASValidator': isFAASValidator,
        'isMapDataManager': isMapDataManager,
        'rpuOwner': rpuOwner,
        'region': region,
        'province': province,
        'municipality': municipality,
        'municipalityAccess': municipalityAccess,
        'restrictedRpuFields': restrictedRpuFields,
      };
}

/// User domain entity, derived from the login response
class UserEntity {
  final int id;
  final String fullName;
  final String emailAddress;
  final bool isSuperAdmin;
  final bool isRPUValidator;
  final bool isPremiumAccount;
  final String? region;
  final String? province;
  final String? municipality;
  final List<String> municipalityAccess;

  UserEntity({
    required this.id,
    required this.fullName,
    required this.emailAddress,
    required this.isSuperAdmin,
    required this.isRPUValidator,
    required this.isPremiumAccount,
    this.region,
    this.province,
    this.municipality,
    required this.municipalityAccess,
  });

  factory UserEntity.fromLoginResponse(LoginResponseDto dto) => UserEntity(
        id: dto.id,
        fullName: dto.fullName,
        emailAddress: dto.emailAddress,
        isSuperAdmin: dto.isSuperAdmin,
        isRPUValidator: dto.isRPUValidator,
        isPremiumAccount: dto.isPremiumAccount,
        region: dto.region,
        province: dto.province,
        municipality: dto.municipality,
        municipalityAccess: dto.municipalityAccess,
      );
}
