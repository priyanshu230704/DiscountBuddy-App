import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:discount_buddy/features/mystery_guest/models/mystery_visit.dart';
import 'package:discount_buddy/core/config/api_endpoints.dart';
import 'package:discount_buddy/core/config/environment.dart';
import 'package:discount_buddy/core/network/api_service.dart';

/// Service for Mystery Guest related API calls
class MysteryGuestService {
  final ApiService _apiService = ApiService();

  /// List all assigned mystery visits
  Future<List<MysteryVisit>> getAssignedVisits({
    String? status,
    int? restaurantId,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;
      if (restaurantId != null) {
        queryParams['restaurant'] = restaurantId.toString();
      }

      final response = await _apiService.get(
        ApiEndpoints.mysteryVisits,
        queryParameters: queryParams,
      );

      final List<dynamic> results =
          (response['results'] ?? []) as List<dynamic>;

      return results
          .map((json) => MysteryVisit.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load mystery visits: ${e.toString()}');
    }
  }

  /// Get details for a specific mystery visit
  Future<MysteryVisit> getVisitDetail(int id) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.mysteryVisitDetail(id),
      );
      return MysteryVisit.fromJson(response);
    } catch (e) {
      throw Exception('Failed to load mystery visit detail: ${e.toString()}');
    }
  }

  /// Start a mystery visit
  Future<MysteryVisit> startVisit(int id) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.startMysteryVisit(id),
      );
      return MysteryVisit.fromJson(response);
    } catch (e) {
      throw Exception('Failed to start mystery visit: ${e.toString()}');
    }
  }

  /// Submit a mystery visit report
  Future<MysteryVisit> submitVisit({
    required int id,
    required Map<String, dynamic> reportData,
  }) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.submitMysteryVisit(id),
        body: reportData,
      );
      return MysteryVisit.fromJson(response);
    } catch (e) {
      throw Exception('Failed to submit mystery visit: ${e.toString()}');
    }
  }

  /// Upload evidence for a mystery visit
  Future<MysteryEvidence> uploadEvidence({
    required int visitId,
    required File file,
    String? description,
  }) async {
    try {
      final endpoint = ApiEndpoints.uploadMysteryEvidence(visitId);
      final url = '${Environment.userApiUrl}$endpoint';

      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers.addAll(_apiService.headers);

      if (description != null) {
        request.fields['description'] = description;
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        return MysteryEvidence.fromJson(decoded as Map<String, dynamic>);
      } else {
        throw Exception('Upload failed with status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to upload evidence: ${e.toString()}');
    }
  }
}
