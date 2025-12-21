import '../services/api_service.dart';
import '../models/wallet.dart';

/// Wallet service for handling wallet-related API calls
class WalletService {
  static final WalletService _instance = WalletService._internal();
  factory WalletService() => _instance;
  WalletService._internal();

  final ApiService _apiService = ApiService();

  /// Get wallet balance
  Future<Wallet> getWallet() async {
    try {
      final response = await _apiService.get('/wallet/');
      return Wallet.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }
}
