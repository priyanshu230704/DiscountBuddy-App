import '../services/api_service.dart';
import '../models/wallet.dart';
import '../config/api_endpoints.dart';

/// Wallet service for handling wallet-related API calls
class WalletService {
  static final WalletService _instance = WalletService._internal();
  factory WalletService() => _instance;
  WalletService._internal();

  final ApiService _apiService = ApiService();

  /// Get wallet balance
  Future<Wallet> getWallet() async {
    try {
      final response = await _apiService.get(ApiEndpoints.wallet);
      return Wallet.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }
}
