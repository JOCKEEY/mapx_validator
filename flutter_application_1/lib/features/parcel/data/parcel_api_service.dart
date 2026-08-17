import 'package:dio/dio.dart';

import '../../../core/constants/app_constants.dart';
import '../domain/parcel_models.dart';

/// API service for parcel endpoints
class ParcelApiService {
  final Dio dio;

  ParcelApiService({required this.dio});

  /// Search parcels by PIN or TD Number
  Future<List<ParcelSearchResult>> searchParcels(String query) async {
    try {
      final response = await dio.get(
        ApiConstants.searchParcelsEndpoint,
        queryParameters: {'q': query},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data
            .map((item) => ParcelSearchResult.fromJson(item))
            .toList();
      } else {
        throw Exception('Search failed with status ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Search request failed: ${e.message}');
    }
  }

  /// Get detailed parcel information
  Future<ParcelDto> getParcelDetails(String parcelId) async {
    try {
      final response = await dio.get(
        '${ApiConstants.parcelDetailsEndpoint}/$parcelId',
      );

      if (response.statusCode == 200) {
        return ParcelDto.fromJson(response.data);
      } else {
        throw Exception('Get parcel failed with status ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Get parcel request failed: ${e.message}');
    }
  }

  /// Get suggestions for parcel search
  Future<List<ParcelSearchResult>> getSuggestions(String query) async {
    try {
      final response = await dio.get(
        ApiConstants.suggestParcelsEndpoint,
        queryParameters: {'q': query},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data
            .map((item) => ParcelSearchResult.fromJson(item))
            .toList();
      } else {
        throw Exception('Suggestions failed with status ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Suggestions request failed: ${e.message}');
    }
  }

  /// Download parcels for a barangay (offline download)
  Future<List<ParcelDto>> downloadParcelsForBarangay(String barangayId) async {
    try {
      final response = await dio.get(
        ApiConstants.offlineParcelsEndpoint,
        queryParameters: {'barangay_id': barangayId},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((item) => ParcelDto.fromJson(item)).toList();
      } else {
        throw Exception(
            'Download failed with status ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Download request failed: ${e.message}');
    }
  }
}
