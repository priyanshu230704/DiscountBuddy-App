/// Auth-specific failure aliases — prefer core types for new code.
export 'package:discount_buddy/core/domain/failures/app_failure.dart';

import 'package:discount_buddy/core/domain/failures/app_failure.dart';

/// Kept for existing auth imports; same as [AppFailure].
typedef AuthFailure = AppFailure;
