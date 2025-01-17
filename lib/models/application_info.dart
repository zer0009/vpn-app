class ApplicationInfo {
  final String packageName;
  final String appName;
  final String? appIcon;
  final bool isSystemApp;

  ApplicationInfo({
    required this.packageName,
    required this.appName,
    this.appIcon,
    this.isSystemApp = false,
  });

  factory ApplicationInfo.fromMap(Map<String, dynamic> map) {
    return ApplicationInfo(
      packageName: map['packageName'] as String,
      appName: map['appName'] as String,
      appIcon: map['appIcon'] as String?,
      isSystemApp: map['isSystemApp'] as bool? ?? false,
    );
  }
} 