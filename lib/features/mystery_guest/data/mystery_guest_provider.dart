import 'dart:io';
import 'package:flutter/material.dart';
import 'package:discount_buddy/core/domain/failures/failure.dart';
import 'package:discount_buddy/features/mystery_guest/data/mystery_guest_repository_impl.dart';
import 'package:discount_buddy/features/mystery_guest/domain/repositories/mystery_guest_repository.dart';
import 'package:discount_buddy/features/mystery_guest/domain/usecases/mystery_guest_usecases.dart';
import 'package:discount_buddy/features/mystery_guest/models/mystery_visit.dart';

/// Mystery Guest state and use case provider.
class MysteryGuestProvider extends ChangeNotifier {
  MysteryGuestProvider({
    MysteryGuestRepository? repository,
    ListAssignedVisitsUseCase? listVisitsUseCase,
    GetVisitDetailUseCase? getDetailUseCase,
    StartVisitUseCase? startUseCase,
    SubmitVisitUseCase? submitUseCase,
    UploadEvidenceUseCase? uploadUseCase,
  })  : _repository = repository ?? MysteryGuestRepositoryImpl(),
        _listVisitsUseCase = listVisitsUseCase,
        _getDetailUseCase = getDetailUseCase,
        _startUseCase = startUseCase,
        _submitUseCase = submitUseCase,
        _uploadUseCase = uploadUseCase;

  final MysteryGuestRepository _repository;
  final ListAssignedVisitsUseCase? _listVisitsUseCase;
  final GetVisitDetailUseCase? _getDetailUseCase;
  final StartVisitUseCase? _startUseCase;
  final SubmitVisitUseCase? _submitUseCase;
  final UploadEvidenceUseCase? _uploadUseCase;

  List<MysteryVisit> _visits = [];
  MysteryVisit? _currentVisit;
  bool _isLoading = false;
  Failure? _failure;

  List<MysteryVisit> get visits => _visits;
  MysteryVisit? get currentVisit => _currentVisit;
  bool get isLoading => _isLoading;
  Failure? get failure => _failure;
  bool get hasError => _failure != null;

  Future<void> loadVisits({String? status, int? restaurantId}) async {
    _isLoading = true;
    _failure = null;
    notifyListeners();

    final useCase = _listVisitsUseCase ?? ListAssignedVisitsUseCase(_repository);
    final result = await useCase(status: status, restaurantId: restaurantId);

    _isLoading = false;
    result.fold(
      onSuccess: (visits) {
        _visits = visits;
        _failure = null;
      },
      onError: (failure) {
        _visits = [];
        _failure = failure;
      },
    );
    notifyListeners();
  }

  Future<void> getVisitDetail(int visitId) async {
    _isLoading = true;
    _failure = null;
    notifyListeners();

    final useCase = _getDetailUseCase ?? GetVisitDetailUseCase(_repository);
    final result = await useCase(visitId);

    _isLoading = false;
    result.fold(
      onSuccess: (visit) {
        _currentVisit = visit;
        _failure = null;
      },
      onError: (failure) {
        _currentVisit = null;
        _failure = failure;
      },
    );
    notifyListeners();
  }

  Future<bool> startVisit(int visitId) async {
    _isLoading = true;
    _failure = null;
    notifyListeners();

    final useCase = _startUseCase ?? StartVisitUseCase(_repository);
    final result = await useCase(visitId);

    _isLoading = false;
    var success = false;
    result.fold(
      onSuccess: (visit) {
        _currentVisit = visit;
        _failure = null;
        success = true;
      },
      onError: (failure) {
        _failure = failure;
      },
    );
    notifyListeners();
    return success;
  }

  Future<bool> submitVisit({
    required int visitId,
    required Map<String, dynamic> reportData,
  }) async {
    _isLoading = true;
    _failure = null;
    notifyListeners();

    final useCase = _submitUseCase ?? SubmitVisitUseCase(_repository);
    final result = await useCase(visitId: visitId, reportData: reportData);

    _isLoading = false;
    var success = false;
    result.fold(
      onSuccess: (visit) {
        _currentVisit = visit;
        _failure = null;
        success = true;
      },
      onError: (failure) {
        _failure = failure;
      },
    );
    notifyListeners();
    return success;
  }

  Future<bool> uploadEvidence({
    required int visitId,
    required File file,
    String? description,
  }) async {
    _isLoading = true;
    _failure = null;
    notifyListeners();

    final useCase = _uploadUseCase ?? UploadEvidenceUseCase(_repository);
    final result = await useCase(
      visitId: visitId,
      file: file,
      description: description,
    );

    _isLoading = false;
    var success = false;
    result.fold(
      onSuccess: (_) {
        _failure = null;
        success = true;
      },
      onError: (failure) {
        _failure = failure;
      },
    );
    notifyListeners();
    return success;
  }
}
