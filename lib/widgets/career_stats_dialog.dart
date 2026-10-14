import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category_model.dart';
import '../models/player_stats.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';

class CareerStatsDialog extends StatefulWidget {
  final String? initialCategoryId;

  const CareerStatsDialog({super.key, this.initialCategoryId});

  @override
  State<CareerStatsDialog> createState() => _CareerStatsDialogState();
}

class _CareerStatsDialogState extends State<CareerStatsDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late String _selectedCatId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedCatId = widget.initialCategoryId ?? 'pop_90s';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final stats = game.playerStats;
    final categories = game.categories;

    // Seçili kategori geçerli mi kontrol et
    if (!categories.any((c) => c.id == _selectedCatId) && categories.isNotEmpty) {
      _selectedCatId = categories.first.id;
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Başlık & Kapat Butonu
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.amber.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.insights_rounded, color: AppTheme.amber, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Kariyer & İstatistikler',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                          Text(
                            'Performans & Müzik Bilgisi Karnesi',
                            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary.withValues(alpha: 0.9)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. Oyuncu & Genel Özet Kartı
              _buildOverallSummaryCard(game, stats),
              const SizedBox(height: 16),

              // 3. Sekme Başlıkları
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppTheme.amber,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.black,
                  unselectedLabelColor: AppTheme.textSecondary,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  tabs: const [
                    Tab(
                      iconMargin: EdgeInsets.only(bottom: 2),
                      icon: Icon(Icons.category_rounded, size: 18),
                      text: 'Kategori Karnesi',
                    ),
                    Tab(
                      iconMargin: EdgeInsets.only(bottom: 2),
                      icon: Icon(Icons.star_rounded, size: 18),
                      text: 'Sanatçı Ustaları',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 4. Sekme İçerikleri
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Sekme 1: Kategori Karnesi
                    _buildCategoryReportTab(categories, stats),

                    // Sekme 2: Tüm Zamanlar En Çok Bilinen Sanatçılar
                    _buildArtistMasteryTab(stats),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverallSummaryCard(GameProvider game, PlayerStats stats) {
    final isSynced = game.googleUserId != null && game.googleUserId!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.surfaceLight,
                child: Text(game.playerAvatar, style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.playerName,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSynced ? AppTheme.emerald : AppTheme.amber,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isSynced ? 'Buluta Yedekli (Google)' : 'Cihazda Saklanıyor',
                          style: TextStyle(
                            fontSize: 10,
                            color: isSynced ? AppTheme.emerald : AppTheme.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // En İyi Seri Rozeti
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.amber.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('EN İYİ SERİ', style: TextStyle(fontSize: 9, color: AppTheme.amber, fontWeight: FontWeight.w700)),
                        Text('${stats.bestStreak} Maç', style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: 12),

          // Metrikler Satırı
          Row(
            children: [
              _buildMiniMetric(
                title: 'Kazanma',
                value: '%${stats.winRate.toStringAsFixed(0)}',
                color: AppTheme.emerald,
                icon: Icons.emoji_events_rounded,
              ),
              _buildMiniMetric(
                title: 'Düello',
                value: '${stats.totalMatches}',
                color: Colors.white,
                icon: Icons.sports_kabaddi_rounded,
              ),
              _buildMiniMetric(
                title: 'G / B / M',
                value: '${stats.wins}/${stats.draws}/${stats.losses}',
                color: AppTheme.amber,
                icon: Icons.pie_chart_rounded,
              ),
              _buildMiniMetric(
                title: 'Doğru Şarkı',
                value: '${stats.totalCorrectAnswers}',
                color: const Color(0xFF38BDF8),
                icon: Icons.music_note_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: color.withValues(alpha: 0.8)),
              const SizedBox(width: 3),
              Text(
                title,
                style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryReportTab(List<MusicCategory> categories, PlayerStats stats) {
    if (categories.isEmpty) {
      return const Center(child: Text('Kategori bulunamadı.', style: TextStyle(color: AppTheme.textMuted)));
    }

    final selectedCategory = categories.firstWhere(
      (c) => c.id == _selectedCatId,
      orElse: () => categories.first,
    );

    final cStats = stats.getCategoryStats(_selectedCatId);
    final topArtists = cStats.topArtists;

    return Column(
      children: [
        // Yatay Kategori Seçici
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, idx) {
              final cat = categories[idx];
              final isSelected = cat.id == _selectedCatId;
              final catColor = cat.badgeColor;

              return InkWell(
                onTap: () => setState(() => _selectedCatId = cat.id),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? catColor.withValues(alpha: 0.2) : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? catColor : AppTheme.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: catColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        cat.title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // Seçili Kategorinin Detay Kartı
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: selectedCategory.badgeColor.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              selectedCategory.title,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: selectedCategory.badgeColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '%${cStats.winRate.toStringAsFixed(0)} Galibiyet Oranı',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: selectedCategory.badgeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // İlerleme Çubuğu
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: cStats.matches > 0 ? (cStats.wins / cStats.matches) : 0.0,
                          minHeight: 6,
                          backgroundColor: AppTheme.background,
                          valueColor: AlwaysStoppedAnimation<Color>(selectedCategory.badgeColor),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Detaylı İstatistik Izgarası
                      Row(
                        children: [
                          _buildDetailStatBox('Toplam Maç', '${cStats.matches}', Icons.sports_esports_rounded),
                          const SizedBox(width: 8),
                          _buildDetailStatBox('Galibiyet', '${cStats.wins}', Icons.check_circle_rounded, color: AppTheme.emerald),
                          const SizedBox(width: 8),
                          _buildDetailStatBox('Beraberlik', '${cStats.draws}', Icons.remove_circle_rounded, color: AppTheme.amber),
                          const SizedBox(width: 8),
                          _buildDetailStatBox('Mağlubiyet', '${cStats.losses}', Icons.cancel_rounded, color: AppTheme.crimson),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.music_note_rounded, size: 16, color: AppTheme.amber),
                                SizedBox(width: 6),
                                Text(
                                  'Bu Kategoride Doğru Bilinen Şarkı:',
                                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                            Text(
                              '${cStats.correctAnswers} Şarkı',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Bu Kategoride En Çok Bildiği Sanatçılar
                Text(
                  '${selectedCategory.title} • En Çok Bildiğin Sanatçılar',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 8),

                if (topArtists.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Bu kategoride henüz doğru şarkı kaydı yok.\nDüellolara girerek rekorunu oluştur!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted, height: 1.4),
                    ),
                  )
                else
                  ...topArtists.take(5).map((entry) {
                    final rank = topArtists.indexOf(entry) + 1;
                    return _buildArtistTile(rank: rank, artist: entry.key, correctCount: entry.value);
                  }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildArtistMasteryTab(PlayerStats stats) {
    final overallTop = stats.topArtists;

    if (overallTop.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.amber.withValues(alpha: 0.1),
                ),
                child: const Icon(Icons.stars_rounded, size: 36, color: AppTheme.amber),
              ),
              const SizedBox(height: 14),
              const Text(
                'Henüz Sanatçı Rekoru Yok',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              const SizedBox(height: 6),
              const Text(
                'Düellolarda doğru cevapladığın şarkıların sanatçıları burada otomatik olarak sıralanır ve en iyi bildiğin müzisyenler taçlandırılır!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted, height: 1.4),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: overallTop.length,
      itemBuilder: (context, idx) {
        final entry = overallTop[idx];
        return _buildArtistTile(
          rank: idx + 1,
          artist: entry.key,
          correctCount: entry.value,
          isGlobal: true,
        );
      },
    );
  }

  Widget _buildDetailStatBox(String label, String value, IconData icon, {Color color = Colors.white}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 14, color: color.withValues(alpha: 0.8)),
            const SizedBox(height: 3),
            Text(
              value,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtistTile({
    required int rank,
    required String artist,
    required int correctCount,
    bool isGlobal = false,
  }) {
    String medal = '$rank.';
    Color medalColor = AppTheme.textSecondary;
    if (rank == 1) {
      medal = '🥇';
      medalColor = AppTheme.amber;
    } else if (rank == 2) {
      medal = '🥈';
      medalColor = const Color(0xFFCBD5E1);
    } else if (rank == 3) {
      medal = '🥉';
      medalColor = const Color(0xFFD97706);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: rank <= 3 ? AppTheme.surfaceLight : AppTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: rank == 1 ? AppTheme.amber.withValues(alpha: 0.4) : AppTheme.border,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              medal,
              style: TextStyle(fontSize: rank <= 3 ? 16 : 13, fontWeight: FontWeight.w800, color: medalColor),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              artist,
              style: TextStyle(
                fontSize: 13,
                fontWeight: rank <= 3 ? FontWeight.w700 : FontWeight.w600,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, size: 12, color: AppTheme.amber),
                const SizedBox(width: 4),
                Text(
                  '$correctCount Doğru',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.amber),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
