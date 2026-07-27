class AppVersionInfo {
  final bool isUpdateAvailable;
  final String updateType;
  final bool isForceUpdate;
  final bool isCriticalUpdate;
  final bool isOptionalUpdate;
  final String? updateMessage;
  final String? latestVersion;
  final String? minimumVersion;
  final String? storeUrl;

  AppVersionInfo({
    required this.isUpdateAvailable,
    required this.updateType,
    required this.isForceUpdate,
    required this.isCriticalUpdate,
    required this.isOptionalUpdate,
    this.updateMessage,
    this.latestVersion,
    this.minimumVersion,
    this.storeUrl,
  });

  factory AppVersionInfo.fromJson(Map<String, dynamic> json) {
    return AppVersionInfo(
      isUpdateAvailable: json['is_update_available'] ?? false,
      updateType: json['update_type'] ?? 'none',
      isForceUpdate: json['is_force_update'] ?? false,
      isCriticalUpdate: json['is_critical_update'] ?? false,
      isOptionalUpdate: json['is_optional_update'] ?? false,
      updateMessage: json['update_message'],
      latestVersion: json['latest_version'],
      minimumVersion: json['minimum_version'],
      storeUrl: json['store_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_update_available': isUpdateAvailable,
      'update_type': updateType,
      'is_force_update': isForceUpdate,
      'is_critical_update': isCriticalUpdate,
      'is_optional_update': isOptionalUpdate,
      'update_message': updateMessage,
      'latest_version': latestVersion,
      'minimum_version': minimumVersion,
      'store_url': storeUrl,
    };
  }
}
