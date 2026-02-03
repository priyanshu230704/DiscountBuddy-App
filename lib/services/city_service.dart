import 'dart:convert';

import '../models/city.dart';
import '../services/api_service.dart';

class CityService {
  final ApiService _apiService = ApiService();

  Future<List<City>> getCities() async {
    try {
      final Map<String, dynamic> body = await _apiService.get(
        '/restaurants/cities/',
      );
      final List results = body["results"] ?? [];
      return results.map((e) => City.fromJson(e)).toList();
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
