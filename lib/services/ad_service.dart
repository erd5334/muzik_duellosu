import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  AdService._();
  static final AdService instance = AdService._();

  // ===========================================================================
  // REKLAM KİMLİKLERİ (ADMOB IDS)
  // Canlıya çıkarken AdMob panelinizden aldığınız kimlikleri buraya yazacaksınız.
  // Şu an Google'ın resmi test kimlikleri tanımlıdır (sorunsuz test edilir).
  // ===========================================================================
  
  // Canlı AdMob kimliklerini test etmek isterseniz true yapabilirsiniz.
  // Varsayılan: false (Google Test Kimlikleri - Banlanmayı ve Geçersiz Tıklamayı Önler)
  static bool forceProductionAds = false;

  // Ödüllü Reklam (Enerji Kazanma: +2 Enerji)
  static String get rewardedAdUnitId => (forceProductionAds || kReleaseMode)
      ? 'ca-app-pub-9240327493687713/5019123389' // Resmi Üretim Kimliği
      : 'ca-app-pub-3940256099942544/5224354917'; // Test Rewarded ID

  // Geçiş Reklamı (Oyun Sonu Reklamı)
  static String get interstitialAdUnitId => (forceProductionAds || kReleaseMode)
      ? 'ca-app-pub-9240327493687713/2192729622' // Resmi Üretim Kimliği
      : 'ca-app-pub-3940256099942544/1033173712'; // Test Interstitial ID

  // Banner Reklam (Ekran altı reklamı)
  static String get bannerAdUnitId => (forceProductionAds || kReleaseMode)
      ? 'ca-app-pub-9240327493687713/8838029025' // Resmi Üretim Kimliği
      : 'ca-app-pub-3940256099942544/6300978111'; // Test Banner ID

  bool _isInitialized = false;
  RewardedAd? _rewardedAd;
  bool _isRewardedLoading = false;

  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;

  Future<void> init() async {
    if (kIsWeb) return; // Web'de mobile ads sdk çalışmaz
    try {
      await MobileAds.instance.initialize();
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          testDeviceIds: [
            '1CD5AED5882B552DA4DF1276DAE34A5A',
          ],
        ),
      );
      _isInitialized = true;
      loadRewardedAd();
      loadInterstitialAd();
    } catch (e) {
      debugPrint('AdMob başlatma hatası: $e');
    }
  }

  // --- Ödüllü Reklam (Rewarded) ---
  void loadRewardedAd() {
    if (kIsWeb || !_isInitialized || _isRewardedLoading) return;
    _isRewardedLoading = true;

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedLoading = false;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad yüklenemedi: ${error.message}');
          _rewardedAd = null;
          _isRewardedLoading = false;
        },
      ),
    );
  }

  void showRewardedAd({
    required VoidCallback onRewarded,
    required void Function(String message) onError,
  }) {
    if (kIsWeb) {
      // Web veya simülasyonda doğrudan ödül ver
      onRewarded();
      return;
    }

    if (_rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _rewardedAd = null;
          loadRewardedAd(); // Bir sonraki için önceden yükle
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _rewardedAd = null;
          loadRewardedAd();
          onError('Reklam gösterilemedi: ${error.message}');
        },
      );

      _rewardedAd!.show(
        onUserEarnedReward: (adWithoutView, reward) {
          onRewarded();
        },
      );
    } else {
      loadRewardedAd();
      onError('Reklam henüz hazır değil, lütfen 2-3 saniye sonra tekrar deneyin.');
    }
  }

  // --- Geçiş Reklamı (Interstitial) ---
  void loadInterstitialAd() {
    if (kIsWeb || !_isInitialized || _isInterstitialLoading) return;
    _isInterstitialLoading = true;

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial ad yüklenemedi: ${error.message}');
          _interstitialAd = null;
          _isInterstitialLoading = false;
        },
      ),
    );
  }

  int _matchCountSinceLastAd = 0;
  static const int interstitialInterval = 3; // Her 3 oyunda bir geçiş reklamı gösterilir

  void showInterstitialAd({VoidCallback? onDismissed}) {
    _matchCountSinceLastAd++;
    if (_matchCountSinceLastAd < interstitialInterval) {
      debugPrint('[AdMob] Geçiş reklamı atlandı ($_matchCountSinceLastAd / $interstitialInterval oyun)');
      onDismissed?.call();
      return;
    }

    _matchCountSinceLastAd = 0;

    if (kIsWeb) {
      onDismissed?.call();
      return;
    }

    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _interstitialAd = null;
          loadInterstitialAd();
          onDismissed?.call();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _interstitialAd = null;
          loadInterstitialAd();
          onDismissed?.call();
        },
      );
      _interstitialAd!.show();
    } else {
      loadInterstitialAd();
      onDismissed?.call();
    }
  }

  // --- Banner Reklam ---
  BannerAd? createBannerAd({
    required VoidCallback onLoaded,
    required void Function(LoadAdError) onFailed,
  }) {
    if (kIsWeb) return null;
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => onLoaded(),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          onFailed(error);
        },
      ),
    )..load();
  }
}
