import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/mystery_guest/domain/repositories/mystery_guest_repository.dart';
import 'package:discount_buddy/features/mystery_guest/models/mystery_visit.dart';

class ListAssignedVisitsUseCase {
  ListAssignedVisitsUseCase(this._repository);
  final MysteryGuestRepository _repository;

  Future<Result<List<MysteryVisit>>> call({
    String? status,
    int? restaurantId,
  }) {
    return _repository.listAssignedVisits(
      status: status,
      restaurantId: restaurantId,
    );
  }
}
