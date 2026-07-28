import 'package:discount_buddy/core/network/api_service.dart';
import 'package:discount_buddy/features/deals/models/voucher.dart';
import 'package:discount_buddy/core/config/api_endpoints.dart';

/// Deals service for handling deal-related API calls.
class DealsService {
  static final DealsService _instance = DealsService._internal();
  factory DealsService() => _instance;
  DealsService._internal();

  final ApiService _apiService = ApiService();

  /// Get vouchers for current user (merchant)
  Future<PaginatedVouchers> getUserVouchers({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.userVouchers,
        queryParameters: {
          'page': page.toString(),
          'page_size': pageSize.toString(),
        },
      );
      return PaginatedVouchers.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Claim a deal by ID
  Future<Map<String, dynamic>> claimDeal(int dealId) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.claimDeal(dealId),
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Create loyalty-only visit (check-in)
  Future<Map<String, dynamic>> createLoyaltyOnlyVisit(String slug) async {
    try {
      final response = await _apiService.post(
        '/restaurants/$slug/visit/loyalty-only',
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Get deal uses for current user
  Future<List<dynamic>> getDealUses() async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.dealUses,
      );
      final results = response['results'];
      if (results is List) {
        return List<dynamic>.from(results);
      }
      final data = response['data'];
      if (data is List) {
        return List<dynamic>.from(data);
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }
}
