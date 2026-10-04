class ImageVariants {
  final String? medium;
  final String? large;

  const ImageVariants({this.medium, this.large});

  factory ImageVariants.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ImageVariants();
    return ImageVariants(
      medium: json['medium'] as String?,
      large: json['large'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medium': medium,
      'large': large,
    };
  }

  /// Best URL for the requested display context.
  String? urlFor({required bool fullScreen}) =>
      fullScreen ? (large ?? medium) : (medium ?? large);
}

/// Reads a media URL from either a plain string or nested `{ medium, large }`.
String? parseApiImageUrl(dynamic raw) {
  if (raw is String && raw.trim().isNotEmpty) return raw.trim();
  if (raw is Map) {
    final medium = raw['medium'];
    final large = raw['large'];
    if (medium is String && medium.trim().isNotEmpty) return medium.trim();
    if (large is String && large.trim().isNotEmpty) return large.trim();
  }
  return null;
}
