import 'dart:io';
import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/mystery_guest/domain/repositories/mystery_guest_repository.dart';
import 'package:discount_buddy/features/mystery_guest/models/mystery_visit.dart';

class ListAssignedVisitsUseCase {
  ListAssignedVisitsUseCase(this._repository);

  final MysteryGuestRepository _repository;

  Future<Result<List<MysteryVisit>>> call({
    String? status,
    int? restaurantId,
  }) async {
    return await _repository.listAssignedVisits(
      status: status,
      restaurantId: restaurantId,
    );
  }
}

class GetVisitDetailUseCase {
  GetVisitDetailUseCase(this._repository);

  final MysteryGuestRepository _repository;

  Future<Result<MysteryVisit>> call(int visitId) async {
    return await _repository.getVisitDetail(visitId);
  }
}

class StartVisitUseCase {
  StartVisitUseCase(this._repository);

  final MysteryGuestRepository _repository;

  Future<Result<MysteryVisit>> call(int visitId) async {
    return await _repository.startVisit(visitId);
  }
}

class SubmitVisitUseCase {
  SubmitVisitUseCase(this._repository);

  final MysteryGuestRepository _repository;

  Future<Result<MysteryVisit>> call({
    required int visitId,
    required Map<String, dynamic> reportData,
  }) async {
    return await _repository.submitVisit(
      visitId: visitId,
      reportData: reportData,
    );
  }
}

class UploadEvidenceUseCase {
  UploadEvidenceUseCase(this._repository);

  final MysteryGuestRepository _repository;

  Future<Result<MysteryEvidence>> call({
    required int visitId,
    required File file,
    String? description,
  }) async {
    return await _repository.uploadEvidence(
      visitId: visitId,
      file: file,
      description: description,
    );
  }
}
