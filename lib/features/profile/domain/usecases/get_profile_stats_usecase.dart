import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/profile/domain/repositories/profile_repository.dart';
import 'package:discount_buddy/features/profile/models/user_interactions.dart';

/// Get user profile stats
class GetProfileStatsUseCase {
  GetProfileStatsUseCase(this._repository);
  final ProfileRepository _repository;

  Future<Result<ProfileStats>> call() => _repository.getProfileStats();
}
