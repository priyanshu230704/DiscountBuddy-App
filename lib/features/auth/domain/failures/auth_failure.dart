import 'package:discount_buddy/features/auth/domain/failures/failure.dart';

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

/// Session is invalid; caller should treat user as logged out.
class UnauthorizedFailure extends AuthFailure {
  const UnauthorizedFailure([super.message = 'Session expired']);
}

/// User dismissed Google/Apple sign-in — do not show as an error snackbar.
class CancelledFailure extends AuthFailure {
  const CancelledFailure([super.message = 'Cancelled']);
}
