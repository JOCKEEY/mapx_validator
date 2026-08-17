import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../domain/validation_models.dart';

/// API service for validation endpoints
class ValidationApiService {
  final Dio dio;

  ValidationApiService({required this.dio});

  /// Submit a field validation for a land parcel, with optional photos
  Future<void> createRpuLandValidation({
    required CreateValidationRequest validation,
    List<String>? photoPaths,
  }) async {
    late final Response response;
    try {
      final formData = FormData.fromMap({
        'id': validation.parcelId,
        if (validation.tdNumber != null) 'tdNumber': validation.tdNumber,
        'remarks': validation.remarks ?? '',
        'lon': validation.longitude,
        'lat': validation.latitude,
        'surveyDate': DateFormat('yyyy-MM-dd').format(validation.surveyDate),
      });

      if (photoPaths != null && photoPaths.isNotEmpty) {
        for (final path in photoPaths) {
          formData.files.add(
            MapEntry('file', await MultipartFile.fromFile(path)),
          );
        }
      }

      response = await dio.post(
        ApiConstants.createRpuLandValidationEndpoint,
        data: formData,
      );
    } on DioException catch (e) {
      throw Exception('Send validation failed: ${e.message}');
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_extractErrorMessage(response));
    }
  }

  /// Extract a human-readable error message from a failed response
  String _extractErrorMessage(Response response) {
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'] ?? data['error'] ?? data['error_description'];
      if (message != null) return message.toString();
    }
    return 'Send validation failed with status ${response.statusCode}';
  }

  /// Get validation details
  Future<ValidationDto> getValidation(String validationId) async {
    try {
      final response = await dio.get(
        '${ApiConstants.getValidationEndpoint}/$validationId',
      );

      if (response.statusCode == 200) {
        return ValidationDto.fromJson(response.data);
      } else {
        throw Exception('Get validation failed with status ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Get validation request failed: ${e.message}');
    }
  }

  /// List validations
  Future<List<ValidationDto>> listValidations({
    String? parcelId,
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (parcelId != null) queryParams['parcel_id'] = parcelId;
      if (status != null) queryParams['status'] = status;

      final response = await dio.get(
        ApiConstants.listValidationsEndpoint,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((item) => ValidationDto.fromJson(item)).toList();
      } else {
        throw Exception('List validations failed with status ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('List validations request failed: ${e.message}');
    }
  }
}
