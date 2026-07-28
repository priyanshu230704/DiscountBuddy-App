import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/mystery_guest/domain/repositories/mystery_guest_repository.dart';
import 'package:discount_buddy/features/mystery_guest/models/mystery_visit.dart';

class SubmitVisitUseCase {
  SubmitVisitUseCase(this._repository);
  final MysteryGuestRepository _repository;

  Future<Result<MysteryVisit>> call({
    required int visitId,
    required Map<String, dynamic> reportData,
  }) {
    return _repository.submitVisit(
      visitId: visitId,
      reportData: reportData,
    );
  }
}
