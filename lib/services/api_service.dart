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

  // Base headers - store as instance variable to persist auth token
  final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  String? _authToken;

  /// Add authorization token to headers
  void setAuthToken(String token) {
    _authToken = token;
    _headers['Authorization'] = 'Bearer $token';
  }

  /// Remove authorization token from headers
  void removeAuthToken() {
    _authToken = null;
    _headers.remove('Authorization');
  }

  /// Get current auth token
  String? get authToken => _authToken;

  /// Add custom header
  void addHeader(String key, String value) {
    _headers[key] = value;
  }

  /// Remove custom header
  void removeHeader(String key) {
    _headers.remove(key);
  }

  /// Get headers with current auth token if available
  Map<String, String> get headers {
    final headers = Map<String, String>.from(_headers);
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
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
          .get(uri, headers: headers)
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
            headers: headers,
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
            headers: headers,
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
            headers: headers,
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
          .delete(uri, headers: headers)
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
        final errorResponse = jsonDecode(response.body);
        if (errorResponse is Map<String, dynamic>) {
          // Try different error message fields
          if (errorResponse.containsKey('detail')) {
            errorMessage = errorResponse['detail'].toString();
          } else if (errorResponse.containsKey('message')) {
            errorMessage = errorResponse['message'].toString();
          } else {
            // If there are field-specific errors, format them
            final fieldErrors = <String>[];
            errorResponse.forEach((key, value) {
              if (value is List) {
                fieldErrors.addAll(value.map((e) => '$key: $e').toList());
              } else if (value is String) {
                fieldErrors.add('$key: $value');
              }
            });
            if (fieldErrors.isNotEmpty) {
              errorMessage = fieldErrors.join(', ');
            }
          }
          errorData = errorResponse;
        } else {
          errorMessage = errorResponse.toString();
        }
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

