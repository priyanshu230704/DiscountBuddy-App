import 'package:flutter/material.dart';
import 'package:discount_buddy/core/domain/failures/failure.dart';
import 'package:discount_buddy/features/loyalty/data/loyalty_repository_impl.dart';
import 'package:discount_buddy/features/loyalty/domain/repositories/loyalty_repository.dart';
import 'package:discount_buddy/features/loyalty/domain/usecases/get_loyalty_cards_usecase.dart';
import 'package:discount_buddy/features/loyalty/models/loyalty_card.dart';

/// Loyalty state and use case provider.
class LoyaltyProvider extends ChangeNotifier {
  LoyaltyProvider({LoyaltyRepository? repository, GetLoyaltyCardsUseCase? usecase})
    : _repository = repository ?? LoyaltyRepositoryImpl(),
      _useCase = usecase;

  final LoyaltyRepository _repository;
  final GetLoyaltyCardsUseCase? _useCase;

  List<LoyaltyCard> _cards = [];
  bool _isLoading = false;
  Failure? _failure;

  List<LoyaltyCard> get cards => _cards;
  bool get isLoading => _isLoading;
  Failure? get failure => _failure;
  bool get hasError => _failure != null;

  Future<void> loadCards() async {
    _isLoading = true;
    _failure = null;
    notifyListeners();

    final useCase = _useCase ?? GetLoyaltyCardsUseCase(_repository);
    final result = await useCase();

    _isLoading = false;
    result.fold(
      onSuccess: (cards) {
        _cards = cards.where((c) => c.restaurant.loyaltyCardEnabled).toList();
        _failure = null;
      },
      onError: (failure) {
        _cards = [];
        _failure = failure;
      },
    );
    notifyListeners();
  }
}
