import 'package:dio/dio.dart';

import '../../../core/constants/app_constants.dart';
import '../domain/validation_models.dart';

/// API service for validation endpoints
class ValidationApiService {
  final Dio dio;

  ValidationApiService({required this.dio});

  /// Upload validation with photos
  Future<ValidationDto> uploadValidation({
    required CreateValidationRequest validation,
    List<String>? photoPaths,
  }) async {
    try {
      final formData = FormData.fromMap({
        'parcel_id': validation.parcelId,
        'status': validation.status,
        'remarks': validation.remarks ?? '',
        'latitude': validation.latitude,
        'longitude': validation.longitude,
      });

      // Add photo files if provided
      if (photoPaths != null && photoPaths.isNotEmpty) {
        for (int i = 0; i < photoPaths.length; i++) {
          formData.files.add(
            MapEntry(
              'photos',
              await MultipartFile.fromFile(
                photoPaths[i],
                filename: 'photo_$i.jpg',
              ),
            ),
          );
        }
      }

      final response = await dio.post(
        ApiConstants.uploadValidationEndpoint,
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ValidationDto.fromJson(response.data);
      } else {
        throw Exception('Upload failed with status ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Upload request failed: ${e.message}');
    }
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
