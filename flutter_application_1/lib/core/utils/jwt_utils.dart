import 'dart:convert';

/// Decodes the payload of a JWT without verifying its signature.
Map<String, dynamic>? decodeJwtPayload(String token) {
  final parts = token.split('.');
  if (parts.length != 3) return null;

  try {
    final normalized = base64Url.normalize(parts[1]);
    final decoded = utf8.decode(base64Url.decode(normalized));
    return jsonDecode(decoded) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}

/// Returns the JWT's expiration time (from its `exp` claim), if present.
DateTime? jwtExpiry(String token) {
  final exp = decodeJwtPayload(token)?['exp'];
  if (exp is int) {
    return DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true)
        .toLocal();
  }
  return null;
}
