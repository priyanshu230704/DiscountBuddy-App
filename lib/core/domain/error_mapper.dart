import 'package:discount_buddy/core/domain/failures/app_failure.dart';
import 'package:discount_buddy/core/domain/failures/failure.dart';
import 'package:discount_buddy/core/domain/failures/network_failure.dart';
import 'package:discount_buddy/core/network/api_service.dart';

/// Shared mapping from thrown errors → [Failure] (DRY across features).
Failure mapToFailure(Object e, {String fallback = 'Something went wrong'}) {
  if (e is ApiException) {
    final msg = e.message.isNotEmpty ? e.message : fallback;
    final lower = msg.toLowerCase();
    if (e.statusCode == 401 ||
        lower.contains('unauthorized') ||
        lower.contains('401')) {
      return UnauthorizedFailure(msg);
    }
    if (lower.contains('cancelled') ||
        lower.contains('canceled') ||
        lower.contains('googlesigninexceptioncode.canceled')) {
      return CancelledFailure(msg);
    }
    return AppFailure(msg);
  }
  final msg = e.toString().replaceFirst('Exception: ', '');
  final lower = msg.toLowerCase();
  if (lower.contains('cancelled') || lower.contains('canceled')) {
    return CancelledFailure(msg);
  }
  if (lower.contains('socket') ||
      lower.contains('network') ||
      lower.contains('timeout') ||
      lower.contains('connection')) {
    return NetworkFailure(msg);
  }
  return AppFailure(msg.isNotEmpty ? msg : fallback);
}
