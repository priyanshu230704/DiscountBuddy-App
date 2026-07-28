import 'package:flutter/material.dart';
import 'package:discount_buddy/core/domain/failures/failure.dart';
import 'package:discount_buddy/features/bookings/data/booking_repository_impl.dart';
import 'package:discount_buddy/features/bookings/domain/repositories/booking_repository.dart';
import 'package:discount_buddy/features/bookings/domain/usecases/booking_usecases.dart';
import 'package:discount_buddy/features/profile/models/user_interactions.dart';

/// Booking state and use case provider.
class BookingProvider extends ChangeNotifier {
  BookingProvider({
    BookingRepository? repository,
    CreateBookingUseCase? createUseCase,
    ListUserBookingsUseCase? listUseCase,
    UpdateBookingUseCase? updateUseCase,
    DeleteBookingUseCase? deleteUseCase,
    CancelBookingUseCase? cancelUseCase,
  })  : _repository = repository ?? BookingRepositoryImpl(),
        _createUseCase = createUseCase,
        _listUseCase = listUseCase,
        _updateUseCase = updateUseCase,
        _deleteUseCase = deleteUseCase,
        _cancelUseCase = cancelUseCase;

  final BookingRepository _repository;
  final CreateBookingUseCase? _createUseCase;
  final ListUserBookingsUseCase? _listUseCase;
  final UpdateBookingUseCase? _updateUseCase;
  final DeleteBookingUseCase? _deleteUseCase;
  final CancelBookingUseCase? _cancelUseCase;

  List<Booking> _bookings = [];
  bool _isLoading = false;
  Failure? _failure;

  List<Booking> get bookings => _bookings;
  bool get isLoading => _isLoading;
  Failure? get failure => _failure;
  bool get hasError => _failure != null;

  Future<void> loadBookings({String? status}) async {
    _isLoading = true;
    _failure = null;
    notifyListeners();

    final useCase = _listUseCase ?? ListUserBookingsUseCase(_repository);
    final result = await useCase(status: status);

    _isLoading = false;
    result.fold(
      onSuccess: (bookings) {
        _bookings = bookings;
        _failure = null;
      },
      onError: (failure) {
        _bookings = [];
        _failure = failure;
      },
    );
    notifyListeners();
  }

  Future<bool> createBooking({
    required int restaurantId,
    required DateTime bookingDate,
    required int numberOfGuests,
    String? specialRequests,
    String? contactName,
    String? contactPhone,
  }) async {
    _isLoading = true;
    _failure = null;
    notifyListeners();

    final useCase = _createUseCase ?? CreateBookingUseCase(_repository);
    final result = await useCase(
      restaurantId: restaurantId,
      bookingDate: bookingDate,
      numberOfGuests: numberOfGuests,
      specialRequests: specialRequests,
      contactName: contactName,
      contactPhone: contactPhone,
    );

    _isLoading = false;
    var success = false;
    result.fold(
      onSuccess: (booking) {
        _bookings.insert(0, booking);
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

  Future<bool> updateBooking({
    required int bookingId,
    DateTime? bookingDate,
    int? numberOfGuests,
    String? specialRequests,
    String? contactName,
    String? contactPhone,
  }) async {
    _isLoading = true;
    _failure = null;
    notifyListeners();

    final useCase = _updateUseCase ?? UpdateBookingUseCase(_repository);
    final result = await useCase(
      bookingId: bookingId,
      bookingDate: bookingDate,
      numberOfGuests: numberOfGuests,
      specialRequests: specialRequests,
      contactName: contactName,
      contactPhone: contactPhone,
    );

    _isLoading = false;
    var success = false;
    result.fold(
      onSuccess: (updated) {
        final index = _bookings.indexWhere((b) => b.id == bookingId);
        if (index >= 0) {
          _bookings[index] = updated;
        }
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

  Future<bool> deleteBooking(int bookingId) async {
    _isLoading = true;
    _failure = null;
    notifyListeners();

    final useCase = _deleteUseCase ?? DeleteBookingUseCase(_repository);
    final result = await useCase(bookingId);

    _isLoading = false;
    var success = false;
    result.fold(
      onSuccess: (_) {
        _bookings.removeWhere((b) => b.id == bookingId);
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

  Future<bool> cancelBooking(int bookingId) async {
    _isLoading = true;
    _failure = null;
    notifyListeners();

    final useCase = _cancelUseCase ?? CancelBookingUseCase(_repository);
    final result = await useCase(bookingId);

    _isLoading = false;
    var success = false;
    result.fold(
      onSuccess: (_) {
        final index = _bookings.indexWhere((b) => b.id == bookingId);
        if (index >= 0) {
          _bookings.removeAt(index);
        }
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
