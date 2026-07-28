import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/loyalty/models/loyalty_card.dart';

/// Intent-based loyalty contract — queries and commands.
abstract class LoyaltyRepository {
  /// Fetch all loyalty cards for the current user.
  Future<Result<List<LoyaltyCard>>> getLoyaltyCards();
}
