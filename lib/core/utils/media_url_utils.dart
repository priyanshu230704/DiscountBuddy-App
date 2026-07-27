import 'package:discount_buddy/core/config/environment.dart';

/// Resolves API media URLs returned by the backend.
/// Handles relative paths and dev-only localhost URLs using [Environment.baseUrl].
String resolveApiMediaUrl(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return trimmed;

  if (trimmed.startsWith('assets/')) {
    return trimmed;
  }

  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    if (trimmed.contains('127.0.0.1') || trimmed.contains('localhost')) {
      final uri = Uri.parse(trimmed);
      final path = uri.hasQuery ? '${uri.path}?${uri.query}' : uri.path;
      return '${Environment.baseUrl}$path';
    }
    return trimmed;
  }

  if (trimmed.startsWith('/')) {
    return '${Environment.baseUrl}$trimmed';
  }

  return '${Environment.baseUrl}/$trimmed';
}
