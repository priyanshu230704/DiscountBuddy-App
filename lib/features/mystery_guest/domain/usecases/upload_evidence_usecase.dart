import 'dart:io';

import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/mystery_guest/domain/repositories/mystery_guest_repository.dart';
import 'package:discount_buddy/features/mystery_guest/models/mystery_visit.dart';

class UploadEvidenceUseCase {
  UploadEvidenceUseCase(this._repository);
  final MysteryGuestRepository _repository;

  Future<Result<MysteryEvidence>> call({
    required int visitId,
    required File file,
    String? description,
  }) {
    return _repository.uploadEvidence(
      visitId: visitId,
      file: file,
      description: description,
    );
  }
}
