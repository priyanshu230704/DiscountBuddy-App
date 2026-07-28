import 'dart:io';
import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/mystery_guest/models/mystery_visit.dart';

/// Intent-based mystery guest contract.
abstract class MysteryGuestRepository {
  /// List all assigned mystery visits
  Future<Result<List<MysteryVisit>>> listAssignedVisits({
    String? status,
    int? restaurantId,
  });

  /// Get details for a specific mystery visit
  Future<Result<MysteryVisit>> getVisitDetail(int visitId);

  /// Start a mystery visit
  Future<Result<MysteryVisit>> startVisit(int visitId);

  /// Submit a mystery visit report
  Future<Result<MysteryVisit>> submitVisit({
    required int visitId,
    required Map<String, dynamic> reportData,
  });

  /// Upload evidence for a mystery visit
  Future<Result<MysteryEvidence>> uploadEvidence({
    required int visitId,
    required File file,
    String? description,
  });
}
