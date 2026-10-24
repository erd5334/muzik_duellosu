import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../providers/game_provider.dart';

class PurchaseService {
  static final PurchaseService instance = PurchaseService._internal();
  factory PurchaseService() => instance;
  PurchaseService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  // Google Play Console'da oluşturulacak resmi Ürün Kimlikleri (SKU / Product ID)
  static const String idRemoveAds = 'remove_ads';
  static const String idVipClub = 'vip_club';
  static const String idEnergy10 = 'energy_10';
  static const String idEnergy25 = 'energy_25';
  static const String idEnergy60 = 'energy_60';
  static const String idEnergy150 = 'energy_150';
  static const String idEnergy300 = 'energy_300';
  static const String idCoins500 = 'coins_500';
  static const String idCoins1500 = 'coins_1500';
  static const String idCoins4000 = 'coins_4000';
  static const String idCoins10000 = 'coins_10000';

  static const Set<String> defaultProductIds = {
    idRemoveAds,
    idVipClub,
    idEnergy10,
    idEnergy25,
    idEnergy60,
    idEnergy150,
    idEnergy300,
    idCoins500,
    idCoins1500,
    idCoins4000,
    idCoins10000,
  };

  final Map<String, ProductDetails> _products = {};
  Map<String, ProductDetails> get products => _products;

  GameProvider? _activeGameProvider;

  Future<void> init(GameProvider gameProvider) async {
    _activeGameProvider = gameProvider;
    if (kIsWeb) return;

    try {
      _isAvailable = await _iap.isAvailable();
      if (!_isAvailable) {
        debugPrint('[IAP] Google Play faturalandırma servisi şu an kullanılamıyor.');
        return;
      }

      _subscription = _iap.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: () => _subscription?.cancel(),
        onError: (err) => debugPrint('[IAP] Satın alma akışı hatası: $err'),
      );

      await queryDynamicProducts(gameProvider.inAppStoreItems.map((e) => e.id).toSet());
    } catch (e) {
      debugPrint('[IAP] Başlatma hatası: $e');
    }
  }

  /// Sunucudan gelen tüm mağaza ürünlerini Google Play Console'dan dinamik olarak sorgula
  Future<void> queryDynamicProducts(Set<String> customIds) async {
    if (!_isAvailable || kIsWeb) return;
    try {
      final combinedIds = {...defaultProductIds, ...customIds}.where((id) => id.isNotEmpty).toSet();
      final response = await _iap.queryProductDetails(combinedIds);
      if (response.error != null) {
        debugPrint('[IAP] Ürün sorgulama hatası: ${response.error!.message}');
      }
      for (final p in response.productDetails) {
        _products[p.id] = p;
      }
      debugPrint('[IAP] ${_products.length} adet Google Play ürünü başarıyla yüklendi: ${_products.keys.join(', ')}');
    } catch (e) {
      debugPrint('[IAP] Dinamik ürün sorgulama hatası: $e');
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchase in purchaseDetailsList) {
      if (purchase.status == PurchaseStatus.pending) {
        debugPrint('[IAP] İşlem onay bekliyor: ${purchase.productID}');
      } else if (purchase.status == PurchaseStatus.error) {
        debugPrint('[IAP] Satın alma hatası: ${purchase.error?.message}');
        if (purchase.pendingCompletePurchase) {
          _iap.completePurchase(purchase);
        }
      } else if (purchase.status == PurchaseStatus.purchased || purchase.status == PurchaseStatus.restored) {
        _deliverProduct(purchase.productID);
        if (purchase.pendingCompletePurchase) {
          _iap.completePurchase(purchase);
        }
      }
    }
  }

  void _deliverProduct(String productId) {
    if (_activeGameProvider == null) return;
    final game = _activeGameProvider!;
    game.applyStoreItemRewards(productId);
    debugPrint('[IAP] Ürün başarıyla dinamik reçete ile teslim edildi: $productId');
  }

  Future<void> buyProduct({
    required String productId,
    required GameProvider game,
    required VoidCallback onFallbackSuccess,
  }) async {
    _activeGameProvider = game;

    if (!_isAvailable || kIsWeb) {
      debugPrint('[IAP] Google Play kullanılamıyor, test teslimatı yapılıyor: $productId');
      onFallbackSuccess();
      return;
    }

    // Ürün hafızada yoksa Google Play'e anlık son bir sorgu at
    if (!_products.containsKey(productId)) {
      debugPrint('[IAP] $productId hafızada yok, Google Play\'den anlık sorgulanıyor...');
      try {
        final res = await _iap.queryProductDetails({productId});
        if (res.productDetails.isNotEmpty) {
          _products[productId] = res.productDetails.first;
        }
      } catch (e) {
        debugPrint('[IAP] Anlık sorgulama hatası: $e');
      }
    }

    if (_products.containsKey(productId)) {
      final productDetails = _products[productId]!;
      final isNonConsumable = (productId == idRemoveAds || productId == idVipClub);
      final purchaseParam = PurchaseParam(productDetails: productDetails);

      debugPrint('🛒 [IAP BAŞLATILIYOR] Google Play ödeme ekranı açılıyor: ${productDetails.id} (${productDetails.price})');
      if (isNonConsumable) {
        await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      } else {
        await _iap.buyConsumable(purchaseParam: purchaseParam);
      }
    } else {
      debugPrint('⚠️ [IAP UYARI] $productId Google Play Console\'da henüz aktif değil veya bulunamadı!');
      onFallbackSuccess();
    }
  }

  /// Satın Alımları Geri Yükle (Apple StoreKit & Google Play Guideline 3.1.1)
  Future<bool> restorePurchases({GameProvider? game}) async {
    if (game != null) _activeGameProvider = game;
    if (kIsWeb || !_isAvailable) {
      debugPrint('[IAP] Satın alma servisi bu platformda kullanılamıyor.');
      return false;
    }
    try {
      debugPrint('🔄 [IAP RESTORE] Satın alımlar Apple StoreKit / Google Play mağazasından sorgulanıyor...');
      await _iap.restorePurchases();
      return true;
    } catch (e) {
      debugPrint('[IAP RESTORE HATA] Satın alımları geri yükleme hatası: $e');
      return false;
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
