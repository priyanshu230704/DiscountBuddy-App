import 'package:discount_buddy/features/restaurants/models/city.dart';
import 'package:discount_buddy/core/config/api_endpoints.dart';
import 'package:discount_buddy/core/network/api_service.dart';

class CityService {
  final ApiService _apiService = ApiService();

  Future<List<City>> getCities() async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.cities,
        type: ApiType.common,
      );

      final List<dynamic> results = response is List
          ? response as List<dynamic>
          : (response['results'] ?? response['data'] ?? []) as List<dynamic>;

      return results.map((e) => City.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      if (e is ApiException) {
        String errorMessage = "Failed to load cities";
        throw ApiException(
          errorMessage,
          statusCode: e.statusCode,
          data: e.data,
        );
      }
      rethrow;
    }
  }
}
