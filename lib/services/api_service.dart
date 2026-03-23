import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:async';
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

/// Types of APIs available
enum ApiType { user, merchant, common }

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

  /// Callback for handling 401 Unauthorized errors (token refresh)
  Future<bool> Function()? onUnauthorized;

  /// Flag to prevent multiple concurrent refresh calls
  bool _isRefreshing = false;

  /// Queue for requests waiting for token refresh
  final List<Completer<bool>> _refreshWaiters = [];


  /// Add authorization token to headers
  void setAuthToken(String token) {
    _authToken = token;
  }

  /// Remove authorization token from headers
  void removeAuthToken() {
    _authToken = null;
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
    if (_authToken != null && _authToken!.isNotEmpty) {
      if (_authToken!.startsWith('Bearer ')) {
        headers['Authorization'] = _authToken!;
      } else {
        headers['Authorization'] = 'Bearer $_authToken';
      }
    }
    return headers;
  }

  /// Normalize endpoint URL - remove trailing slashes except for root paths
  String _normalizeEndpoint(String endpoint) {
    // Remove trailing slashes, but keep single slash for root
    if (endpoint == '/') {
      return endpoint;
    }

    String path = endpoint;
    String query = '';

    // Split query parameters if present
    if (endpoint.contains('?')) {
      int queryIndex = endpoint.indexOf('?');
      path = endpoint.substring(0, queryIndex);
      query = endpoint.substring(queryIndex);
    }

    // Ensure path starts with /
    if (!path.startsWith('/')) {
      path = '/$path';
    }

    // NOTE: We do NOT force trailing slash here anymore.
    // The caller is responsible for adding it if needed (e.g. for Django list views).

    return path + query;
  }

  /// Get base URL based on ApiType
  String _getBaseUrl(ApiType type) {
    switch (type) {
      case ApiType.user:
        return Environment.userApiUrl;
      case ApiType.merchant:
        return Environment.merchantApiUrl;
      case ApiType.common:
        return Environment.apiUrl;
    }
  }

  // Pending requests cache to avoid redundant concurrent calls
  final Map<String, Future<Map<String, dynamic>>> _pendingRequests = {};

  /// GET request
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParameters,
    ApiType type = ApiType.user,
  }) async {
    final normalizedEndpoint = _normalizeEndpoint(endpoint);
    final baseUrl = _getBaseUrl(type);
    final uri = Uri.parse(
      '$baseUrl$normalizedEndpoint',
    ).replace(queryParameters: queryParameters);
    final requestKey = uri.toString();

    // If there's already a pending request for this exact URI, return it
    if (_pendingRequests.containsKey(requestKey)) {
      if (Environment.enableLogging) {
        debugPrint('DEDUPLICATED: $requestKey');
      }
      return _pendingRequests[requestKey]!;
    }

    final requestFuture = _performGet(uri);
    _pendingRequests[requestKey] = requestFuture;

    try {
      final response = await requestFuture;
      return response;
    } finally {
      // Remove from pending once completed
      _pendingRequests.remove(requestKey);
    }
  }

  /// Internal method to perform the actual GET request
  Future<Map<String, dynamic>> _performGet(Uri uri) async {
    return _sendRequest(() async {
      final request = http.Request('GET', uri)
        ..headers.addAll(headers)
        ..followRedirects = false;

      final streamedResponse =
          await _client.send(request).timeout(Environment.apiTimeout);
      return http.Response.fromStream(streamedResponse);
    });
  }

  /// POST request
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    ApiType type = ApiType.user,
  }) async {
    final normalizedEndpoint = _normalizeEndpoint(endpoint);
    final baseUrl = _getBaseUrl(type);
    final uri = Uri.parse('$baseUrl$normalizedEndpoint');

    return _sendRequest(() async {
      final request = http.Request('POST', uri);
      request.headers.addAll(headers);
      if (body != null) {
        request.body = jsonEncode(body);
      }

      final streamedResponse =
          await _client.send(request).timeout(Environment.apiTimeout);
      return http.Response.fromStream(streamedResponse);
    });
  }

  /// PUT request
  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    ApiType type = ApiType.user,
  }) async {
    final normalizedEndpoint = _normalizeEndpoint(endpoint);
    final baseUrl = _getBaseUrl(type);
    final uri = Uri.parse('$baseUrl$normalizedEndpoint');

    return _sendRequest(() async {
      final request = http.Request('PUT', uri)
        ..headers.addAll(headers)
        ..followRedirects = false;
      if (body != null) {
        request.body = jsonEncode(body);
      }

      final streamedResponse =
          await _client.send(request).timeout(Environment.apiTimeout);
      return http.Response.fromStream(streamedResponse);
    });
  }

  /// PATCH request
  Future<Map<String, dynamic>> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    ApiType type = ApiType.user,
  }) async {
    final normalizedEndpoint = _normalizeEndpoint(endpoint);
    final baseUrl = _getBaseUrl(type);
    final uri = Uri.parse('$baseUrl$normalizedEndpoint');

    return _sendRequest(() async {
      final request = http.Request('PATCH', uri)
        ..headers.addAll(headers)
        ..followRedirects = false;
      if (body != null) {
        request.body = jsonEncode(body);
      }

      final streamedResponse =
          await _client.send(request).timeout(Environment.apiTimeout);
      return http.Response.fromStream(streamedResponse);
    });
  }

  /// POST request with multipart/form-data (for file uploads)
  Future<Map<String, dynamic>> postMultipart(
    String endpoint, {
    Map<String, String>? fields,
    Map<String, http.MultipartFile>? files,
    ApiType type = ApiType.user,
  }) async {
    final normalizedEndpoint = _normalizeEndpoint(endpoint);
    final baseUrl = _getBaseUrl(type);
    final uri = Uri.parse('$baseUrl$normalizedEndpoint');

    return _sendRequest(() async {
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(headers);

      // Update Content-Type for multipart
      request.headers['Content-Type'] = 'multipart/form-data';

      if (fields != null) {
        request.fields.addAll(fields);
      }

      if (files != null) {
        files.forEach((key, value) {
          request.files.add(value);
        });
      }

      final streamedResponse =
          await _client.send(request).timeout(Environment.apiTimeout);
      return http.Response.fromStream(streamedResponse);
    });
  }

  /// PATCH request with multipart/form-data (for file uploads)
  Future<Map<String, dynamic>> patchMultipart(
    String endpoint, {
    Map<String, String>? fields,
    Map<String, http.MultipartFile>? files,
    ApiType type = ApiType.user,
  }) async {
    final normalizedEndpoint = _normalizeEndpoint(endpoint);
    final baseUrl = _getBaseUrl(type);
    final uri = Uri.parse('$baseUrl$normalizedEndpoint');

    return _sendRequest(() async {
      final request = http.MultipartRequest('PATCH', uri);
      request.headers.addAll(headers);

      // Update Content-Type for multipart
      request.headers['Content-Type'] = 'multipart/form-data';

      if (fields != null) {
        request.fields.addAll(fields);
      }

      if (files != null) {
        files.forEach((key, value) {
          request.files.add(value);
        });
      }

      final streamedResponse =
          await _client.send(request).timeout(Environment.apiTimeout);
      return http.Response.fromStream(streamedResponse);
    });
  }

  /// DELETE request
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    Map<String, dynamic>? body,
    ApiType type = ApiType.user,
  }) async {
    final normalizedEndpoint = _normalizeEndpoint(endpoint);
    final baseUrl = _getBaseUrl(type);
    final uri = Uri.parse('$baseUrl$normalizedEndpoint');

    return _sendRequest(() async {
      final request = http.Request('DELETE', uri)
        ..headers.addAll(headers)
        ..followRedirects = false;
      if (body != null) {
        request.body = jsonEncode(body);
      }

      final streamedResponse =
          await _client.send(request).timeout(Environment.apiTimeout);
      return http.Response.fromStream(streamedResponse);
    });
  }

  /// Generic request sender with error handling and token refresh logic
  Future<Map<String, dynamic>> _sendRequest(
    Future<http.Response> Function() requestSender,
  ) async {
    try {
      final response = await requestSender();

      // Check for 401 Unauthorized errors to trigger token refresh
      if (response.statusCode == 401 &&
          onUnauthorized != null &&
          _authToken != null) {
        if (Environment.enableLogging) {
          debugPrint('401 Unauthorized detected. Triggering token refresh...');
        }

        bool refreshSuccess = false;

        if (_isRefreshing) {
          // Wait for the current refresh to finish
          if (Environment.enableLogging) {
            debugPrint('Already refreshing, waiting...');
          }
          final completer = Completer<bool>();
          _refreshWaiters.add(completer);
          refreshSuccess = await completer.future;
        } else {
          // Start refreshing
          _isRefreshing = true;
          try {
            refreshSuccess = await onUnauthorized!();
            if (Environment.enableLogging) {
              debugPrint('Token refresh successful: $refreshSuccess');
            }
          } catch (e) {
            if (Environment.enableLogging) {
              debugPrint('Token refresh failed with exception: $e');
            }
            refreshSuccess = false;
          } finally {
            _isRefreshing = false;
            // Notify all waiting requests
            for (var waiter in _refreshWaiters) {
              waiter.complete(refreshSuccess);
            }
            _refreshWaiters.clear();
          }
        }

        if (refreshSuccess) {
          // Retry the request after successful refresh
          if (Environment.enableLogging) {
            debugPrint('Retrying request after token refresh...');
          }
          final retryResponse = await requestSender();
          return _handleResponse(retryResponse);
        } else {
          // If refresh failed, handle the original 401 error
          return _handleResponse(response);
        }
      }

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }


  /// Handle HTTP response
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (Environment.enableLogging) {
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response: ${response.body}');
    }

    final statusCode = response.statusCode;

    // Handle redirects (301, 302, etc.) - if redirecting to trailing slash version, treat as error
    // since we're preventing redirects to avoid duplicate calls
    if (statusCode >= 300 && statusCode < 400) {
      final location = response.headers['location'];
      if (location != null && Environment.enableLogging) {
        debugPrint(
          'Redirect detected to: $location (prevented to avoid duplicate call)',
        );
      }
      throw ApiException(
        'Server redirected request. This should not happen with normalized endpoints.',
        statusCode: statusCode,
      );
    }

    if (statusCode >= 200 && statusCode < 300) {
      if (response.body.isEmpty) {
        return {'success': true};
      }
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return {
            'data': decoded,
          }; // Wrap lists in a data key for consistency if needed, or return dynamic
        }
        return decoded as Map<String, dynamic>;
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

      throw ApiException(errorMessage, statusCode: statusCode, data: errorData);
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
