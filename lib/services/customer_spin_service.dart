import 'package:flutter/foundation.dart';
import 'api_service.dart';
import '../models/spin_to_win/customer_spin_models.dart';
import 'admin_service.dart';

class CustomerSpinService {
  static final CustomerSpinService _instance = CustomerSpinService._internal();
  factory CustomerSpinService() => _instance;
  CustomerSpinService._internal();

  final ApiService _apiService = ApiService();

  /// GET /api/v1/user/user/spin-to-win/wheel
  Future<SpinWheelResponse> getWheel() async {
    try {
      final response = await _apiService.get(
        '/user/spin-to-win/wheel',
        type: ApiType.customerV1,
        withAuth: true,
      );
      return SpinWheelResponse.fromJson(response);
    } catch (e) {
      debugPrint('CustomerSpinService.getWheel error: $e');
      rethrow;
    }
  }

  /// POST /api/v1/user/user/spin-to-win/spin
  Future<SpinResultResponse> spinWheel() async {
    try {
      final response = await _apiService.post(
        '/user/spin-to-win/spin',
        body: {},
        type: ApiType.customerV1,
        withAuth: true,
      );
      return SpinResultResponse.fromJson(response);
    } catch (e) {
      debugPrint('CustomerSpinService.spinWheel error: $e');
      rethrow;
    }
  }

  /// GET /api/v1/user/user/spin-to-win/my-prizes
  Future<PaginatedResult<CustomerSpinPrize>> getMyPrizes({int page = 1}) async {
    try {
      final response = await _apiService.get(
        '/user/spin-to-win/my-prizes',
        queryParameters: {'page': page.toString()},
        type: ApiType.customerV1,
        withAuth: true,
      );

      List rawList = [];
      if (response['results'] != null && response['results'] is List) {
        rawList = response['results'] as List;
      } else if (response['data'] != null && response['data'] is List) {
        rawList = response['data'] as List;
      } else if (response is List) {
        rawList = response as List;
      }

      final list = rawList
          .whereType<Map<String, dynamic>>()
          .map((item) => CustomerSpinPrize.fromJson(item))
          .toList();

      final count = response['count'] as int? ?? list.length;
      final next = response['next'] as String?;
      final previous = response['previous'] as String?;

      return PaginatedResult(
        count: count,
        next: next,
        previous: previous,
        results: list,
      );
    } catch (e) {
      debugPrint('CustomerSpinService.getMyPrizes error: $e');
      rethrow;
    }
  }
}
