import 'dart:io';
import 'package:discount_buddy/core/domain/error_mapper.dart';
import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/mystery_guest/data/mystery_guest_service.dart';
import 'package:discount_buddy/features/mystery_guest/domain/repositories/mystery_guest_repository.dart';
import 'package:discount_buddy/features/mystery_guest/models/mystery_visit.dart';

class MysteryGuestRepositoryImpl implements MysteryGuestRepository {
  MysteryGuestRepositoryImpl({MysteryGuestService? service})
    : _service = service ?? MysteryGuestService();

  final MysteryGuestService _service;

  @override
  Future<Result<List<MysteryVisit>>> listAssignedVisits({
    String? status,
    int? restaurantId,
  }) async {
    try {
      final visits = await _service.getAssignedVisits(
        status: status,
        restaurantId: restaurantId,
      );
      return Success(visits);
    } catch (e) {
      return Err(mapToFailure(e, fallback: 'Failed to load mystery visits'));
    }
  }

  @override
  Future<Result<MysteryVisit>> getVisitDetail(int visitId) async {
    try {
      final visit = await _service.getVisitDetail(visitId);
      return Success(visit);
    } catch (e) {
      return Err(mapToFailure(e, fallback: 'Failed to load visit detail'));
    }
  }

  @override
  Future<Result<MysteryVisit>> startVisit(int visitId) async {
    try {
      final visit = await _service.startVisit(visitId);
      return Success(visit);
    } catch (e) {
      return Err(mapToFailure(e, fallback: 'Failed to start visit'));
    }
  }

  @override
  Future<Result<MysteryVisit>> submitVisit({
    required int visitId,
    required Map<String, dynamic> reportData,
  }) async {
    try {
      final visit = await _service.submitVisit(
        id: visitId,
        reportData: reportData,
      );
      return Success(visit);
    } catch (e) {
      return Err(mapToFailure(e, fallback: 'Failed to submit visit'));
    }
  }

  @override
  Future<Result<MysteryEvidence>> uploadEvidence({
    required int visitId,
    required File file,
    String? description,
  }) async {
    try {
      final evidence = await _service.uploadEvidence(
        visitId: visitId,
        file: file,
        description: description,
      );
      return Success(evidence);
    } catch (e) {
      return Err(mapToFailure(e, fallback: 'Failed to upload evidence'));
    }
  }
}
