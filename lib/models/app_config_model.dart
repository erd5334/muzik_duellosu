class AppVersionConfig {
  final String minVersion;
  final String latestVersion;
  final bool forceUpdate;
  final String title;
  final String message;
  final String iosUrl;
  final String androidUrl;

  const AppVersionConfig({
    required this.minVersion,
    required this.latestVersion,
    required this.forceUpdate,
    required this.title,
    required this.message,
    required this.iosUrl,
    required this.androidUrl,
  });

  factory AppVersionConfig.fromJson(Map<String, dynamic> json) {
    return AppVersionConfig(
      minVersion: json['min_version'] as String? ?? '1.0.8',
      latestVersion: json['latest_version'] as String? ?? '1.0.8',
      forceUpdate: json['force_update'] as bool? ?? false,
      title: json['title'] as String? ?? 'Yeni Güncelleme Mevcut! 🚀',
      message: json['message'] as String? ??
          'Daha iyi bir müzik deneyimi ve yeni özellikler için lütfen Sahne Senin\'i güncelleyin.',
      iosUrl: json['ios_url'] as String? ?? 'https://apps.apple.com/app/id6738914624',
      androidUrl: json['android_url'] as String? ??
          'https://play.google.com/store/apps/details?id=com.eryazilimci.muzik_duellosu',
    );
  }
}

class AppAnnouncementConfig {
  final bool enabled;
  final String id;
  final String title;
  final String message;
  final String buttonText;

  const AppAnnouncementConfig({
    required this.enabled,
    required this.id,
    required this.title,
    required this.message,
    required this.buttonText,
  });

  factory AppAnnouncementConfig.fromJson(Map<String, dynamic> json) {
    return AppAnnouncementConfig(
      enabled: json['enabled'] as bool? ?? false,
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Sahne Senin Duyurusu 📢',
      message: json['message'] as String? ?? '',
      buttonText: json['button_text'] as String? ?? 'Okudum, Anladım',
    );
  }
}

class AppLiveConfig {
  final AppVersionConfig version;
  final AppAnnouncementConfig announcement;
  final int botMatchWaitSec;

  const AppLiveConfig({
    required this.version,
    required this.announcement,
    required this.botMatchWaitSec,
  });

  factory AppLiveConfig.fromJson(Map<String, dynamic> json) {
    return AppLiveConfig(
      version: AppVersionConfig.fromJson(
        json['version'] as Map<String, dynamic>? ?? {},
      ),
      announcement: AppAnnouncementConfig.fromJson(
        json['announcement'] as Map<String, dynamic>? ?? {},
      ),
      botMatchWaitSec: (json['bot'] as Map<String, dynamic>?)?['matchWaitSec'] as int? ?? 6,
    );
  }
}
