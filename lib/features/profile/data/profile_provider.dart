import 'package:flutter/foundation.dart';
import 'package:discount_buddy/core/domain/failures/failure.dart';
import 'package:discount_buddy/features/profile/data/profile_repository_impl.dart';
import 'package:discount_buddy/features/profile/domain/usecases/get_deal_redemptions_usecase.dart';
import 'package:discount_buddy/features/profile/domain/usecases/get_profile_stats_usecase.dart';
import 'package:discount_buddy/features/profile/domain/usecases/submit_partner_request_usecase.dart';
import 'package:discount_buddy/features/profile/models/user_interactions.dart';
import 'package:discount_buddy/features/deals/models/deal_redemption.dart';

/// Presentation state for profile
class ProfileProvider extends ChangeNotifier {
  ProfileProvider() {
    final repo = ProfileRepositoryImpl();

    _getProfileStatsUseCase = GetProfileStatsUseCase(repo);
    _getDealRedemptionsUseCase = GetDealRedemptionsUseCase(repo);
    _submitPartnerRequestUseCase = SubmitPartnerRequestUseCase(repo);
  }

  late GetProfileStatsUseCase _getProfileStatsUseCase;
  late GetDealRedemptionsUseCase _getDealRedemptionsUseCase;
  late SubmitPartnerRequestUseCase _submitPartnerRequestUseCase;

  ProfileStats? _profileStats;
  List<DealRedemption> _dealRedemptions = [];
  Failure? _error;
  bool _isLoading = false;

  // Getters
  ProfileStats? get profileStats => _profileStats;
  List<DealRedemption> get dealRedemptions => _dealRedemptions;
  Failure? get error => _error;
  bool get isLoading => _isLoading;

  /// Get profile stats
  Future<void> getProfileStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _getProfileStatsUseCase();

    result.fold(
      onSuccess: (stats) {
        _profileStats = stats;
        _error = null;
      },
      onError: (failure) {
        _error = failure;
        _profileStats = null;
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  /// Get deal redemptions
  Future<void> getDealRedemptions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _getDealRedemptionsUseCase();

    result.fold(
      onSuccess: (redemptions) {
        _dealRedemptions = redemptions;
        _error = null;
      },
      onError: (failure) {
        _error = failure;
        _dealRedemptions = [];
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  /// Submit partner request
  Future<void> submitPartnerRequest({
    required String restaurantName,
    required String contactName,
    required String email,
    required String phone,
    required String cityName,
    String? website,
    String? comments,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _submitPartnerRequestUseCase(
      restaurantName: restaurantName,
      contactName: contactName,
      email: email,
      phone: phone,
      cityName: cityName,
      website: website,
      comments: comments,
    );

    result.fold(
      onSuccess: (_) {
        _error = null;
      },
      onError: (failure) {
        _error = failure;
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  /// Clear all state
  void clear() {
    _profileStats = null;
    _dealRedemptions = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
