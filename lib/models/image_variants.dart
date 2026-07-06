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
