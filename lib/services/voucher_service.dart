import '../services/api_service.dart';
import '../models/voucher.dart';
import '../config/api_endpoints.dart';

/// Voucher service for handling voucher-related API calls
class VoucherService {
  static final VoucherService _instance = VoucherService._internal();
  factory VoucherService() => _instance;
  VoucherService._internal();

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
}
