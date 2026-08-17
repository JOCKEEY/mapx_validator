/// Simple auth models without Freezed for quick testing
/// TODO: Migrate back to Freezed once code generation works properly

/// Login request DTO
class LoginRequestDto {
  final String username;
  final String password;

  LoginRequestDto({
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
    'username': username,
    'password': password,
  };

  factory LoginRequestDto.fromJson(Map<String, dynamic> json) =>
      LoginRequestDto(
        username: json['username'] as String,
        password: json['password'] as String,
      );
}

/// User DTO
class UserDto {
  final String id;
  final String name;
  final String email;

  UserDto({
    required this.id,
    required this.name,
    required this.email,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
  };

  factory UserDto.fromJson(Map<String, dynamic> json) =>
      UserDto(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
      );
}

/// Login response DTO
class LoginResponseDto {
  final String accessToken;
  final String? refreshToken;
  final UserDto user;
  final DateTime? expiresAt;

  LoginResponseDto({
    required this.accessToken,
    this.refreshToken,
    required this.user,
    this.expiresAt,
  });

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'user': user.toJson(),
    'expiresAt': expiresAt?.toIso8601String(),
  };

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) =>
      LoginResponseDto(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String?,
        user: UserDto.fromJson(json['user'] as Map<String, dynamic>),
        expiresAt: json['expiresAt'] != null 
            ? DateTime.parse(json['expiresAt'] as String)
            : null,
      );
}

/// User domain entity
class UserEntity {
  final String id;
  final String name;
  final String email;

  UserEntity({
    required this.id,
    required this.name,
    required this.email,
  });

  factory UserEntity.fromDto(UserDto dto) {
    return UserEntity(
      id: dto.id,
      name: dto.name,
      email: dto.email,
    );
  }

  UserDto toDto() => UserDto(
    id: id,
    name: name,
    email: email,
  );
}

