import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/store_item.dart';
import '../providers/game_provider.dart';
import '../services/ad_service.dart';
import '../services/purchase_service.dart';
import '../theme/app_theme.dart';

class StoreDialog extends StatelessWidget {
  const StoreDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final iapProducts = PurchaseService.instance.products;

    // Uzaktan veya varsayılan mağaza öğeleri
    final vipItems = game.inAppStoreItems.where((i) => i.id == 'vip_club' || i.id == 'remove_ads').toList();
    final coinItems = game.inAppStoreItems.where((i) => i.id.startsWith('coins_')).toList();
    final energyItems = game.inAppStoreItems.where((i) => i.id.startsWith('energy_')).toList();
    final jokerItems = game.inGameStoreItems;

    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppTheme.border, width: 1.5),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Başlık & Kapat Butonu
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.storefront_rounded, color: AppTheme.amber, size: 26),
                      const SizedBox(width: 8),
                      const Text(
                        'Müzik Mağazası',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Row(
                          children: [
                            const Text('⚡', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 3),
                            Text(
                              game.energy >= GameProvider.maxEnergy
                                  ? '${game.energy}/${GameProvider.maxEnergy}'
                                  : '${game.energy}/${GameProvider.maxEnergy} (${game.minutesUntilNextEnergy}d)',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.amber),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Row(
                          children: [
                            const Text('🪙', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 3),
                            Text(
                              '${game.coins}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.amber),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: AppTheme.border, height: 20),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Ücretsiz Reklam Bölümü
                      _buildSectionTitle('ÜCRETSİZ ENERJİ'),
                      const SizedBox(height: 8),
                      _buildAdEnergyCard(context, game),
                      const SizedBox(height: 20),

                      // 2. Altın ile Joker Al (%50 Joker Takası)
                      if (jokerItems.isNotEmpty) ...[
                        _buildSectionTitle('ALTIN İLE JOKER AL (50/50)'),
                        const SizedBox(height: 8),
                        ...jokerItems.map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: _buildGoldExchangeItem(
                              context: context,
                              game: game,
                              item: item,
                            ),
                          );
                        }),
                        const SizedBox(height: 20),
                      ],

                      // 3. Özel VIP & Reklamsızlık Paketleri (Google Play)
                      if (vipItems.isNotEmpty) ...[
                        _buildSectionTitle('ÖZEL AVANTAJ PAKETLERİ'),
                        const SizedBox(height: 8),
                        ...vipItems.map((item) {
                          final iap = iapProducts[item.id];
                          final displayPrice = iap?.price ?? item.priceLabel;
                          final isVip = item.id == 'vip_club';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: _buildVipPackageCard(
                              context,
                              game,
                              title: item.title,
                              price: displayPrice,
                              badge: item.badgeLabel.isNotEmpty ? item.badgeLabel : (isVip ? '👑 VIP' : '🛡️ TEMİZ OYUN'),
                              badgeColor: isVip ? AppTheme.amber : AppTheme.emerald,
                              features: isVip
                                  ? [
                                      'Ömür Boyu Reklamsız Kullanım',
                                      'Anında Sınırsız Enerji Deposu',
                                      'Anında +10 Adet 50/50 Jokeri',
                                      '👑 Altın İsim & Özel Profil Rozeti',
                                    ]
                                  : [
                                      'Ömür Boyu Tüm Geçiş ve Banner Reklamları Kalkar',
                                      'Kesintisiz, Hızlı ve Akıcı Oyun Deneyimi',
                                    ],
                              onTap: () {
                                PurchaseService.instance.buyProduct(
                                  productId: item.id,
                                  game: game,
                                  onFallbackSuccess: () {
                                    game.applyStoreItemRewards(item.id);
                                    _showPurchaseSuccess(context, '${item.title} aktif edildi!');
                                  },
                                );
                              },
                            ),
                          );
                        }),
                        const SizedBox(height: 20),
                      ],

                      // 4. Altın Paketleri (Plak & Rozet Koleksiyonu İçin)
                      if (coinItems.isNotEmpty) ...[
                        _buildSectionTitle('ALTIN PAKETLERİ (PLAK KOLEKSİYONU)'),
                        const SizedBox(height: 8),
                        ...coinItems.map((item) {
                          final iap = iapProducts[item.id];
                          final displayPrice = iap?.price ?? item.priceLabel;
                          final isPopular = item.badgeLabel.isNotEmpty || item.id == 'coins_1500';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: _buildStoreRowItem(
                              title: item.title,
                              subtitle: item.subtitle,
                              price: displayPrice,
                              icon: item.icon,
                              badge: item.badgeLabel,
                              isHighlighted: isPopular,
                              onTap: () {
                                PurchaseService.instance.buyProduct(
                                  productId: item.id,
                                  game: game,
                                  onFallbackSuccess: () {
                                    game.applyStoreItemRewards(item.id);
                                    _showPurchaseSuccess(context, '${item.title} hesaba yüklendi!');
                                  },
                                );
                              },
                            ),
                          );
                        }),
                        const SizedBox(height: 20),
                      ],

                      // 5. Enerji & Joker Paketleri (Google Play)
                      if (energyItems.isNotEmpty) ...[
                        _buildSectionTitle('ENERJİ & JOKER PAKETLERİ'),
                        const SizedBox(height: 8),
                        ...energyItems.map((item) {
                          final iap = iapProducts[item.id];
                          final displayPrice = iap?.price ?? item.priceLabel;
                          final isHighlighted = item.badgeLabel.isNotEmpty;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: _buildStoreRowItem(
                              title: item.title,
                              subtitle: item.subtitle,
                              price: displayPrice,
                              icon: item.icon,
                              badge: item.badgeLabel,
                              isHighlighted: isHighlighted,
                              onTap: () {
                                PurchaseService.instance.buyProduct(
                                  productId: item.id,
                                  game: game,
                                  onFallbackSuccess: () {
                                    game.applyStoreItemRewards(item.id);
                                    _showPurchaseSuccess(context, '${item.title} hesaba yüklendi!');
                                  },
                                );
                              },
                            ),
                          );
                        }),
                        const SizedBox(height: 12),
                      ],

                      // Satın Alımları Geri Yükle (Apple StoreKit & Google Play Guideline 3.1.1)
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton.icon(
                          onPressed: () async {
                            final success = await PurchaseService.instance.restorePurchases(game: game);
                            if (context.mounted) {
                              if (success) {
                                _showPurchaseSuccess(
                                  context,
                                  'Satın alımlarınız kontrol edildi ve geçerli haklarınız geri yüklendi! 🔄',
                                );
                              } else {
                                _showPurchaseError(
                                  context,
                                  'Geri yüklenecek aktif bir satın alım bulunamadı.',
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.restore_rounded, size: 16, color: AppTheme.textMuted),
                          label: const Text(
                            'Satın Alımları Geri Yükle (Restore Purchases)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textMuted,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.amber, letterSpacing: 0.8),
    );
  }

  Widget _buildAdEnergyCard(BuildContext context, GameProvider game) {
    final remainingAds = GameProvider.maxDailyAdsForEnergy - game.dailyAdsWatchedForEnergy;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.emerald.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Text('🎬', style: TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Reklam İzle ➔ +2 Enerji', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  'Bugün kalan hak: $remainingAds / ${GameProvider.maxDailyAdsForEnergy}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: remainingAds > 0
                ? () {
                    AdService.instance.showRewardedAd(
                      onRewarded: () {
                        game.watchAdForEnergy();
                        _showPurchaseSuccess(context, 'Tebrikler! +2 Enerji hesabınıza yüklendi.');
                      },
                      onError: (errMsg) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(errMsg),
                            backgroundColor: AppTheme.crimson,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    );
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.emerald,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('İzle', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  /// Altın ile Joker Alma Satırı
  Widget _buildGoldExchangeItem({
    required BuildContext context,
    required GameProvider game,
    required StoreItem item,
  }) {
    final canAfford = game.coins >= item.coinsCost;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.badgeLabel.isNotEmpty ? AppTheme.amber.withValues(alpha: 0.6) : AppTheme.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Text(item.icon, style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(item.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                    if (item.badgeLabel.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.amber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.badgeLabel,
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.amber),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(item.subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!canAfford) {
                _showPurchaseError(context, 'Yetersiz Altın! (${item.coinsCost} Altın gerekiyor, sende ${game.coins} var)');
                return;
              }
              final success = await game.buyStoreItemWithCoins(item);
              if (success && context.mounted) {
                _showPurchaseSuccess(context, 'Tebrikler! ${item.rewards.jokers} Adet %50 Jokeri eklendi!');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: canAfford ? AppTheme.amber : AppTheme.surface,
              foregroundColor: canAfford ? Colors.black : AppTheme.textMuted,
              side: BorderSide(color: canAfford ? AppTheme.amber : AppTheme.border),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🪙', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Text(
                  '${item.coinsCost}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVipPackageCard(
    BuildContext context,
    GameProvider game, {
    required String title,
    required String price,
    required String badge,
    required Color badgeColor,
    required List<String> features,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: badgeColor.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: badgeColor, letterSpacing: 0.5),
                ),
              ),
              Text(
                price,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 8),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 14, color: AppTheme.emerald),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(f, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: badgeColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Hemen Satın Al ($price)', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreRowItem({
    required String title,
    required String subtitle,
    required String price,
    required String icon,
    String badge = '',
    bool isHighlighted = false,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isHighlighted ? AppTheme.amber : AppTheme.border),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                    if (badge.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.amber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.amber),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: isHighlighted ? AppTheme.amber : AppTheme.surface,
              foregroundColor: isHighlighted ? Colors.black : Colors.white,
              side: BorderSide(color: isHighlighted ? AppTheme.amber : AppTheme.border),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(price, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  void _showPurchaseSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.emerald,
        behavior: SnackBarBehavior.floating,
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
      ),
    );
  }

  void _showPurchaseError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.crimson,
        behavior: SnackBarBehavior.floating,
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
      ),
    );
  }
}
