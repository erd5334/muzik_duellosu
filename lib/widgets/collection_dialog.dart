import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/collection_badge.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';
import 'store_dialog.dart';

class CollectionDialog extends StatefulWidget {
  final String? initialCategoryId;
  const CollectionDialog({super.key, this.initialCategoryId});

  @override
  State<CollectionDialog> createState() => _CollectionDialogState();
}

class _CollectionDialogState extends State<CollectionDialog> {
  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();

    // Kategorileri dinamik olarak belirle:
    // 1. game.categories listesindeki rozeti olan tüm kategorileri al
    final List<Map<String, String>> dynamicCategories = [];
    final Set<String> addedCategoryIds = {};

    for (final cat in game.categories) {
      if (cat.id == 'karma_all') continue;
      final count = game.badges.where((b) => b.categoryId == cat.id).length;
      if (count > 0) {
        dynamicCategories.add({
          'id': cat.id,
          'label': cat.title,
        });
        addedCategoryIds.add(cat.id);
      }
    }

    // 2. game.badges içinde yer alıp categories tablosunda eşleşmemiş olan varsa onları da sekme olarak ekle
    for (final b in game.badges) {
      if (!addedCategoryIds.contains(b.categoryId) && b.categoryId.isNotEmpty) {
        dynamicCategories.add({
          'id': b.categoryId,
          'label': b.categoryId,
        });
        addedCategoryIds.add(b.categoryId);
      }
    }

    if (dynamicCategories.isEmpty) {
      dynamicCategories.add({'id': 'all', 'label': 'Tüm Plaklar'});
    }

    int initialIndex = 0;
    if (widget.initialCategoryId != null) {
      final foundIdx = dynamicCategories.indexWhere((c) => c['id'] == widget.initialCategoryId);
      if (foundIdx != -1) {
        initialIndex = foundIdx;
      }
    }

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
          child: DefaultTabController(
            initialIndex: initialIndex.clamp(0, dynamicCategories.isNotEmpty ? dynamicCategories.length - 1 : 0),
            length: dynamicCategories.length,
            child: Column(
              children: [
                // Başlık
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.stars_rounded, color: AppTheme.amber, size: 26),
                        const SizedBox(width: 8),
                        const Text(
                          'Plak Koleksiyonu',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Row(
                            children: [
                              const Text('🪙', style: TextStyle(fontSize: 11)),
                              const SizedBox(width: 4),
                              Text(
                                '${game.coins}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.amber),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => _showShardConverterSheet(context, game),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)]),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3), blurRadius: 4),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Text('✨', style: TextStyle(fontSize: 11)),
                                const SizedBox(width: 4),
                                Text(
                                  '${game.jokerShards}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.add_circle, color: Colors.white70, size: 13),
                              ],
                            ),
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
                const SizedBox(height: 10),

                // Dinamik Kategori Sekmeleri (Yatay Kaydırılabilir)
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      color: AppTheme.amber,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    labelColor: Colors.black,
                    unselectedLabelColor: AppTheme.textSecondary,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                    tabs: dynamicCategories.map((c) => Tab(text: c['label'])).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // Dinamik TabBarView
                Expanded(
                  child: TabBarView(
                    children: dynamicCategories.map((cat) {
                      final catBadges = (cat['id'] == 'all')
                          ? game.badges
                          : game.badges.where((b) => b.categoryId == cat['id']).toList();

                      if (catBadges.isEmpty) {
                        return const Center(
                          child: Text(
                            'Bu kategoride henüz plak bulunmuyor.',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                          ),
                        );
                      }

                      return ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: catBadges.length,
                        itemBuilder: (context, index) {
                          final badge = catBadges[index];
                          return _buildBadgeCard(context, game, badge);
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeCard(BuildContext context, GameProvider game, CollectionBadge badge) {
    final costToComplete = badge.remainingShards * 10; // Her parça 10 Altın

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: badge.isUnlocked ? AppTheme.amber.withValues(alpha: 0.6) : AppTheme.border,
          width: badge.isUnlocked ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Gerçekçi Plak Rozet Diski & Sanatçı Fotoğrafı
              _buildVinylDisc(badge),
              const SizedBox(width: 14),

              // Sanatçı ve Unvan
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            badge.artistName,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge.tier,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.amber),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      badge.title,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Durum Butonu
              if (badge.isUnlocked)
                ElevatedButton(
                  onPressed: badge.isEquipped ? null : () => game.equipBadge(badge.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: badge.isEquipped ? AppTheme.emerald : AppTheme.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    badge.isEquipped ? 'Takılı' : 'Avatar Yap',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: badge.isEquipped ? Colors.white : Colors.black,
                    ),
                  ),
                ),
            ],
          ),

          if (!badge.isUnlocked) ...[
            const SizedBox(height: 14),
            // İlerleme Barı (Parçalar)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Plak Parçaları: ${badge.currentShards} / ${badge.totalShardsRequired}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
                ),
                Text(
                  'Kalan: ${badge.remainingShards}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.amber),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: badge.progress,
                minHeight: 8,
                backgroundColor: AppTheme.surface,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.amber),
              ),
            ),
            const SizedBox(height: 12),

            // PARÇA DOLDURMA BUTONLARI (Joker Parça & Altın)
            Row(
              children: [
                // 1. Joker Parça Butonu
                Expanded(
                  flex: 5,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      if (game.jokerShards > 0) {
                        final toUse = min(game.jokerShards, badge.remainingShards);
                        final success = game.useJokerShardsOnBadge(badge.id, toUse);
                        if (success) {
                          if (badge.isUnlocked) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppTheme.emerald,
                                content: Text('🎉 ${badge.artistName} Plak Rozeti açıldı!'),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: const Color(0xFF8B5CF6),
                                content: Text('✨ $toUse Joker Parça basıldı! Kalan: ${badge.remainingShards}'),
                              ),
                            );
                          }
                        }
                      } else {
                        _showShardConverterSheet(context, game);
                      }
                    },
                    icon: const Text('✨', style: TextStyle(fontSize: 14)),
                    label: Text(
                      game.jokerShards > 0
                          ? 'Joker Bas (${min(game.jokerShards, badge.remainingShards)})'
                          : 'Joker Parça Al',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF8B5CF6)),
                      backgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 2. Altın ile Tamamla Butonu
                Expanded(
                  flex: 5,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final success = game.buyMissingShards(badge.id, costToComplete);
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppTheme.emerald,
                            content: Text('${badge.artistName} Plak Rozeti açıldı!'),
                          ),
                        );
                      } else {
                        final needed = costToComplete - game.coins;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppTheme.crimson,
                            content: Text('$needed Altın eksik!'),
                            action: SnackBarAction(
                              label: 'MAĞAZA',
                              textColor: AppTheme.amber,
                              onPressed: () {
                                showDialog(context: context, builder: (_) => const StoreDialog());
                              },
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Text('🪙', style: TextStyle(fontSize: 12)),
                    label: Text(
                      'Tamamla ($costToComplete)',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.amber),
                      backgroundColor: AppTheme.amber.withValues(alpha: 0.1),
                      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVinylDisc(CollectionBadge badge) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF101014),
        boxShadow: [
          BoxShadow(
            color: badge.isUnlocked
                ? AppTheme.amber.withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.4),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
        border: Border.all(
          color: badge.isUnlocked ? AppTheme.amber : Colors.white24,
          width: 2.0,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Plak olukları çizgisi
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white10, width: 1.2),
            ),
          ),
          // Sanatçı Gerçek Fotoğrafı (Merkez Plak Göbeği)
          ClipOval(
            child: SizedBox(
              width: 36,
              height: 36,
              child: badge.imageUrl.isNotEmpty
                  ? Image.network(
                      badge.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Text(badge.emoji, style: const TextStyle(fontSize: 16)),
                      ),
                    )
                  : Center(
                      child: Text(badge.emoji, style: const TextStyle(fontSize: 16)),
                    ),
            ),
          ),
          // Kilitliyse Koyu Filtre ve Kilit İkonu
          if (!badge.isUnlocked)
            Container(
              width: 54,
              height: 54,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black54,
              ),
              child: const Center(
                child: Icon(Icons.lock_rounded, size: 16, color: Colors.white70),
              ),
            ),
        ],
      ),
    );
  }

  void _showShardConverterSheet(BuildContext context, GameProvider game) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: AppTheme.border, width: 1.5),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(22.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Başlık & Kapat
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)]),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('✨', style: TextStyle(fontSize: 18)),
                          ),
                          const SizedBox(width: 10),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Joker Parça Atölyesi',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white),
                              ),
                              Text(
                                'Her plağa uyumlu evrensel parçalar',
                                style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Bakiye Bilgisi
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Mevcut Joker Parçan:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
                        ),
                        Row(
                          children: [
                            const Text('✨', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 4),
                            Text(
                              '${game.jokerShards} Parça',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFFA78BFA)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  const Text(
                    '🪙 Altın ile Joker Parça Üret',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.amber),
                  ),
                  const SizedBox(height: 10),

                  // Paketler
                  Row(
                    children: [
                      _buildConverterOption(
                        title: '1 Parça',
                        cost: 100,
                        gain: 1,
                        game: game,
                        onSuccess: () => setModalState(() {}),
                      ),
                      const SizedBox(width: 8),
                      _buildConverterOption(
                        title: '5 Parça',
                        badgeText: '-%10',
                        cost: 450,
                        gain: 5,
                        game: game,
                        onSuccess: () => setModalState(() {}),
                      ),
                      const SizedBox(width: 8),
                      _buildConverterOption(
                        title: '10 Parça',
                        badgeText: '-%20',
                        cost: 800,
                        gain: 10,
                        game: game,
                        onSuccess: () => setModalState(() {}),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Fazla Parçaları Tara & Dönüştür
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Text('♻️', style: TextStyle(fontSize: 15)),
                            SizedBox(width: 8),
                            Text(
                              'Fazlalık Parçaları Kurtar',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Koleksiyonu tamamlanan plaklardaki fazlalık parçalar boşa gitmez, Joker Parçaya dönüştürülür.',
                          style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final converted = game.convertExcessBadgeShards();
                              setModalState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: converted > 0 ? AppTheme.emerald : AppTheme.surfaceLight,
                                  content: Text(
                                    converted > 0
                                        ? '✨ $converted adet fazlalık parça Joker Parçaya dönüştürüldü!'
                                        : 'Tüm plak parçalarınız dengede, fazlalık bulunmuyor.',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.recycling_rounded, size: 16),
                            label: const Text('Fazla Parçaları Tara & Dönüştür', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6D28D9),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildConverterOption({
    required String title,
    String? badgeText,
    required int cost,
    required int gain,
    required GameProvider game,
    required VoidCallback onSuccess,
  }) {
    final canAfford = game.coins >= cost;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (canAfford) {
            final ok = game.convertCoinsToJokerShards(cost, gain);
            if (ok) {
              onSuccess();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF8B5CF6),
                  content: Text('✨ +$gain Joker Plak Parçası üretildi!'),
                ),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: AppTheme.crimson,
                content: Text('Yeterli altınınız yok!'),
              ),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: canAfford ? const Color(0xFF8B5CF6).withValues(alpha: 0.12) : AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: canAfford ? const Color(0xFF8B5CF6).withValues(alpha: 0.5) : AppTheme.border,
            ),
          ),
          child: Column(
            children: [
              if (badgeText != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.crimson,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ),
              Text(
                '✨ $title',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                '$cost 🪙',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: canAfford ? AppTheme.amber : AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
