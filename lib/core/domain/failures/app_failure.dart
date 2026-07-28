import 'package:discount_buddy/core/domain/failures/failure.dart';

/// Generic application/domain failure.
class AppFailure extends Failure {
  const AppFailure(super.message);
}

/// Session is invalid; caller should treat user as logged out.
class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure([super.message = 'Session expired']);
}

/// User dismissed a flow (e.g. social login) — do not show as an error snackbar.
class CancelledFailure extends AppFailure {
  const CancelledFailure([super.message = 'Cancelled']);
}
