import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../services/ad_service.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _initBanner();
  }

  void _initBanner() {
    if (kIsWeb) return;
    _bannerAd?.dispose();
    _bannerAd = AdService.instance.createBannerAd(
      onLoaded: () {
        debugPrint('✅ [AdMob] Banner reklam başarıyla yüklendi!');
        if (mounted) {
          setState(() {
            _isLoaded = true;
            _statusMessage = null;
          });
        }
      },
      onFailed: (error) {
        final msg = 'Hata: ${error.code} - ${error.message}';
        debugPrint('❌ [AdMob] Banner yüklenemedi: $msg (adUnitId: ${AdService.bannerAdUnitId})');
        if (mounted) {
          setState(() {
            _isLoaded = false;
            _statusMessage = msg;
          });
          // Ağ gecikmeleri için 10 saniye sonra tekrar dene
          Future.delayed(const Duration(seconds: 10), () {
            if (mounted && !_isLoaded) {
              _initBanner();
            }
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return const SizedBox.shrink();

    final game = context.watch<GameProvider>();
    // Reklamları Kaldır veya VIP üyeliği varsa banner tamamen gizlenir
    if (game.hasNoAds || game.isVip) {
      return const SizedBox.shrink();
    }

    if (!_isLoaded || _bannerAd == null) {
      // Geliştirme (Debug) modunda kullanıcıya reklamın durumunu gösterir
      if (kDebugMode && _statusMessage != null) {
        return SafeArea(
          child: Container(
            color: const Color(0xFF1E293B),
            height: 50,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline, color: Colors.amber, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AdMob: $_statusMessage',
                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }
      return const SizedBox.shrink();
    }

    return SafeArea(
      child: Container(
        color: Colors.transparent,
        width: double.infinity,
        height: _bannerAd!.size.height.toDouble(),
        alignment: Alignment.center,
        child: SizedBox(
          width: _bannerAd!.size.width.toDouble(),
          height: _bannerAd!.size.height.toDouble(),
          child: AdWidget(ad: _bannerAd!),
        ),
      ),
    );
  }
}
