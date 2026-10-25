import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_config_model.dart';
import '../services/music_api_service.dart';
import '../theme/app_theme.dart';

class AppNoticeDialog {
  static bool _hasChecked = false;

  static Future<void> checkAndShow(BuildContext context) async {
    if (_hasChecked) return;
    _hasChecked = true;

    try {
      final config = await MusicApiService().fetchAppConfig();
      if (config == null || !context.mounted) return;

      // 1. Zorunlu Güncelleme Kontrolü
      if (config.version.forceUpdate) {
        final isOlder = _isVersionOlder(
          MusicApiService.currentAppVersion,
          config.version.minVersion,
        );

        if (isOlder && context.mounted) {
          _showForceUpdateDialog(context, config.version);
          return; // Güncelleme zorunlu ise duyuruya geçme
        }
      }

      // 2. Açılış Duyuru Modu Kontrolü
      if (config.announcement.enabled && config.announcement.id.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final lastSeenId = prefs.getString('last_seen_announcement_id');

        if (lastSeenId != config.announcement.id && context.mounted) {
          _showAnnouncementDialog(context, config.announcement);
        }
      }
    } catch (e) {
      debugPrint('AppNoticeDialog error: $e');
    }
  }

  static bool _isVersionOlder(String current, String target) {
    try {
      final cParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final tParts = target.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      for (int i = 0; i < 3; i++) {
        final c = i < cParts.length ? cParts[i] : 0;
        final t = i < tParts.length ? tParts[i] : 0;
        if (c < t) return true;
        if (c > t) return false;
      }
    } catch (_) {}
    return false;
  }

  static void _showForceUpdateDialog(BuildContext context, AppVersionConfig version) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.amber, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.amber.withValues(alpha: 0.25),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.amber.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.amber.withValues(alpha: 0.4)),
                  ),
                  child: const Center(
                    child: Text('🚀', style: TextStyle(fontSize: 32)),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  version.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  version.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.amber,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () async {
                      final urlStr = (!kIsWeb && Platform.isIOS)
                          ? version.iosUrl
                          : version.androidUrl;
                      final uri = Uri.parse(urlStr);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: const Text(
                      'Hemen Güncelle',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void _showAnnouncementDialog(
    BuildContext context,
    AppAnnouncementConfig announcement,
  ) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.border, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.amber.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.amber.withValues(alpha: 0.4)),
                ),
                child: const Center(
                  child: Text('📢', style: TextStyle(fontSize: 30)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                announcement.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Text(
                    announcement.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.amber,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    try {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString(
                        'last_seen_announcement_id',
                        announcement.id,
                      );
                    } catch (_) {}
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                  child: Text(
                    announcement.buttonText.isNotEmpty
                        ? announcement.buttonText
                        : 'Okudum, Anladım',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
