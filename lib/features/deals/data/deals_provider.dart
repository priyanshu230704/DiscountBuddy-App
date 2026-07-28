import 'package:flutter/material.dart';
import 'package:discount_buddy/features/deals/data/deals_repository_impl.dart';
import 'package:discount_buddy/features/deals/domain/repositories/deals_repository.dart';
import 'package:discount_buddy/features/deals/domain/usecases/claim_deal_usecase.dart';
import 'package:discount_buddy/features/deals/domain/usecases/create_loyalty_checkin_usecase.dart';
import 'package:discount_buddy/features/deals/domain/usecases/get_deal_uses_usecase.dart';
import 'package:discount_buddy/features/deals/domain/usecases/get_user_vouchers_usecase.dart';
import 'package:discount_buddy/features/deals/models/voucher.dart';
import 'package:discount_buddy/core/domain/result.dart';

class DealsProvider extends ChangeNotifier {
  final DealsRepository _repository;
  late final GetUserVouchersUseCase _getUserVouchersUseCase;
  late final ClaimDealUseCase _claimDealUseCase;
  late final CreateLoyaltyCheckinUseCase _createLoyaltyCheckinUseCase;
  late final GetDealUsesUseCase _getDealUsesUseCase;

  DealsProvider({DealsRepository? repository})
      : _repository = repository ?? DealsRepositoryImpl() {
    _getUserVouchersUseCase = GetUserVouchersUseCase(_repository);
    _claimDealUseCase = ClaimDealUseCase(_repository);
    _createLoyaltyCheckinUseCase = CreateLoyaltyCheckinUseCase(_repository);
    _getDealUsesUseCase = GetDealUsesUseCase(_repository);
  }

  PaginatedVouchers? _vouchers;
  List<dynamic>? _dealUses;
  bool _isLoading = false;
  String? _errorMessage;

  PaginatedVouchers? get vouchers => _vouchers;
  List<dynamic>? get dealUses => _dealUses;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadVouchers({int page = 1, int pageSize = 20}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _getUserVouchersUseCase(
      page: page,
      pageSize: pageSize,
    );

    _isLoading = false;
    result.fold(
      onSuccess: (vouchers) {
        _vouchers = vouchers;
        notifyListeners();
      },
      onError: (failure) {
        _errorMessage = failure.message;
        notifyListeners();
      },
    );
  }

  Future<Result<Map<String, dynamic>>> claimDeal(int dealId) async {
    final result = await _claimDealUseCase.claimDeal(dealId);
    result.fold(
      onSuccess: (_) {
        notifyListeners();
      },
      onError: (failure) {
        _errorMessage = failure.message;
        notifyListeners();
      },
    );
    return result;
  }

  Future<Result<Map<String, dynamic>>> createLoyaltyCheckIn(
    String restaurantSlug,
  ) async {
    final result = await _createLoyaltyCheckinUseCase(restaurantSlug);
    result.fold(
      onSuccess: (_) {
        notifyListeners();
      },
      onError: (failure) {
        _errorMessage = failure.message;
        notifyListeners();
      },
    );
    return result;
  }

  Future<void> loadDealUses() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _getDealUsesUseCase();

    _isLoading = false;
    result.fold(
      onSuccess: (dealUses) {
        _dealUses = dealUses;
        notifyListeners();
      },
      onError: (failure) {
        _errorMessage = failure.message;
        notifyListeners();
      },
    );
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
