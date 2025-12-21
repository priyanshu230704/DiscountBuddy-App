import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/environment.dart';

/// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException(this.message, {this.statusCode, this.data});

  @override
  String toString() => message;
}

/// Common API Service for handling HTTP requests
class ApiService {
  // Singleton instance
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // HTTP Client
  final http.Client _client = http.Client();

  // Base headers
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  /// Add authorization token to headers
  void setAuthToken(String token) {
    _headers['Authorization'] = 'Bearer $token';
  }

  /// Remove authorization token from headers
  void removeAuthToken() {
    _headers.remove('Authorization');
  }

  /// Add custom header
  void addHeader(String key, String value) {
    _headers[key] = value;
  }

  /// Remove custom header
  void removeHeader(String key) {
    _headers.remove(key);
  }

  /// GET request
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParameters,
  }) async {
    try {
      final uri = Uri.parse('${Environment.apiUrl}$endpoint')
          .replace(queryParameters: queryParameters);

      if (Environment.enableLogging) {
        print('GET: $uri');
      }

      final response = await _client
          .get(uri, headers: _headers)
          .timeout(Environment.apiTimeout);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// POST request
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = Uri.parse('${Environment.apiUrl}$endpoint');

      if (Environment.enableLogging) {
        print('POST: $uri');
        print('Body: $body');
      }

      final response = await _client
          .post(
            uri,
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(Environment.apiTimeout);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// PUT request
  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = Uri.parse('${Environment.apiUrl}$endpoint');

      if (Environment.enableLogging) {
        print('PUT: $uri');
        print('Body: $body');
      }

      final response = await _client
          .put(
            uri,
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(Environment.apiTimeout);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// PATCH request
  Future<Map<String, dynamic>> patch(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = Uri.parse('${Environment.apiUrl}$endpoint');

      if (Environment.enableLogging) {
        print('PATCH: $uri');
        print('Body: $body');
      }

      final response = await _client
          .patch(
            uri,
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(Environment.apiTimeout);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// DELETE request
  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final uri = Uri.parse('${Environment.apiUrl}$endpoint');

      if (Environment.enableLogging) {
        print('DELETE: $uri');
      }

      final response = await _client
          .delete(uri, headers: _headers)
          .timeout(Environment.apiTimeout);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Handle HTTP response
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (Environment.enableLogging) {
      print('Status Code: ${response.statusCode}');
      print('Response: ${response.body}');
    }

    final statusCode = response.statusCode;

    if (statusCode >= 200 && statusCode < 300) {
      if (response.body.isEmpty) {
        return {'success': true};
      }
      try {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        return {'data': response.body};
      }
    } else {
      String errorMessage = 'Request failed with status: $statusCode';
      dynamic errorData;

      try {
        final errorResponse = jsonDecode(response.body) as Map<String, dynamic>;
        errorMessage = errorResponse['message'] ?? errorMessage;
        errorData = errorResponse;
      } catch (e) {
        errorMessage = response.body.isNotEmpty
            ? response.body
            : 'Request failed with status: $statusCode';
      }

      throw ApiException(
        errorMessage,
        statusCode: statusCode,
        data: errorData,
      );
    }
  }

  /// Handle errors
  ApiException _handleError(dynamic error) {
    if (error is ApiException) {
      return error;
    } else if (error is http.ClientException) {
      return ApiException('Network error: ${error.message}');
    } else if (error is FormatException) {
      return ApiException('Invalid response format');
    } else {
      return ApiException('An unexpected error occurred: ${error.toString()}');
    }
  }

  /// Dispose resources
  void dispose() {
    _client.close();
  }
}

