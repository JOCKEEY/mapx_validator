import 'package:dio/dio.dart';

import '../../../core/constants/app_constants.dart';
import '../domain/land_search_utils.dart';
import '../domain/parcel_models.dart';

/// API service for parcel/land endpoints
class ParcelApiService {
  final Dio dio;

  ParcelApiService({required this.dio});

  /// Search land parcels by PIN or TD Number. Multiple values may be
  /// comma-separated; `searchBy` is auto-detected from the query.
  Future<List<LandParcel>> searchLand(String query) async {
    final cleanedQuery = cleanSearchQuery(query);
    if (cleanedQuery.isEmpty) return [];

    late final Response response;
    try {
      response = await dio.post(
        ApiConstants.searchLandEndpoint,
        data: FormData.fromMap({
          'search': cleanedQuery,
          'searchBy': detectSearchBy(cleanedQuery),
        }),
      );
    } on DioException catch (e) {
      throw Exception('Search request failed: ${e.message}');
    }

    if (response.statusCode == 200) {
      final data = response.data;
      final List<dynamic> items = data is Map<String, dynamic>
          ? (data['data'] as List<dynamic>? ?? [])
          : (data as List<dynamic>? ?? []);
      return items
          .map((item) => LandParcel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    throw Exception(_extractErrorMessage(response));
  }

  /// Extract a human-readable error message from a failed response
  String _extractErrorMessage(Response response) {
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'] ?? data['error'] ?? data['error_description'];
      if (message != null) return message.toString();
    }
    return 'Search failed with status ${response.statusCode}';
  }
}
