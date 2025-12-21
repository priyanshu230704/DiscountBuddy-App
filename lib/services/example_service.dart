import 'api_service.dart';

/// Example service demonstrating how to use the API service
/// This is a template - replace with your actual service implementations
class ExampleService {
  final ApiService _apiService = ApiService();

  /// Example: Get data from API
  Future<Map<String, dynamic>> getExampleData() async {
    try {
      final response = await _apiService.get('/example');
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Example: Post data to API
  Future<Map<String, dynamic>> createExampleData(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiService.post('/example', body: data);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Example: Update data via API
  Future<Map<String, dynamic>> updateExampleData(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiService.put('/example/$id', body: data);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Example: Delete data via API
  Future<Map<String, dynamic>> deleteExampleData(String id) async {
    try {
      final response = await _apiService.delete('/example/$id');
      return response;
    } catch (e) {
      rethrow;
    }
  }
}

