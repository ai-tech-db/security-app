class InstalledApp {
  final String packageName;
  final String label;
  final String versionName;
  final int firstInstallTime;
  final int lastUpdateTime;
  final bool isSystem;
  final bool isDeviceAdmin;
  final List<String> permissions;

  const InstalledApp({
    required this.packageName,
    required this.label,
    required this.versionName,
    required this.firstInstallTime,
    required this.lastUpdateTime,
    required this.isSystem,
    required this.isDeviceAdmin,
    required this.permissions,
  });

  factory InstalledApp.fromMap(Map<dynamic, dynamic> m) => InstalledApp(
        packageName: m['packageName'] as String? ?? '',
        label: m['label'] as String? ?? '',
        versionName: m['versionName'] as String? ?? '',
        firstInstallTime: m['firstInstallTime'] as int? ?? 0,
        lastUpdateTime: m['lastUpdateTime'] as int? ?? 0,
        isSystem: m['isSystem'] as bool? ?? false,
        isDeviceAdmin: m['isDeviceAdmin'] as bool? ?? false,
        permissions: (m['permissions'] as List?)?.cast<String>() ?? const [],
      );

  List<String> get riskReasons {
    final reasons = <String>[];
    final p = permissions.toSet();
    if (p.contains('android.permission.BIND_ACCESSIBILITY_SERVICE')) {
      reasons.add('Accessibility');
    }
    if (isDeviceAdmin) reasons.add('Device Admin');
    if (p.contains('android.permission.SYSTEM_ALERT_WINDOW')) {
      reasons.add('Overlay');
    }
    if (p.contains('android.permission.RECEIVE_SMS') &&
        p.contains('android.permission.READ_SMS')) {
      reasons.add('SMS Access');
    }
    return reasons;
  }

  int get riskScore {
    if (isSystem) return 0;
    var score = 0;
    final reasons = riskReasons;
    if (reasons.contains('Accessibility')) score += 30;
    if (reasons.contains('Device Admin')) score += 25;
    if (reasons.contains('Overlay')) score += 20;
    if (reasons.contains('SMS Access')) score += 15;
    return score.clamp(0, 100);
  }

  bool get isSuspicious => riskScore >= 50;

  String get riskLabel {
    if (riskScore >= 75) return 'High';
    if (riskScore >= 50) return 'Medium';
    if (riskScore >= 25) return 'Low';
    return 'Minimal';
  }
}
