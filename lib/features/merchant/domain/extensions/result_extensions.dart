// Extension to make Result compatible with direct assignment patterns
import 'package:discount_buddy/core/domain/result.dart';

extension ResultCompat<T> on Result<T> {
  /// Get value or return default, for direct assignment convenience
  T getOrElse(T defaultValue) => valueOrNull ?? defaultValue;
}
